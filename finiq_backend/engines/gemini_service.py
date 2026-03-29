import os
import time
import threading
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

_client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
_MODEL = 'gemini-2.0-flash'

ARTHA_SYSTEM_PROMPT_EN = """
You are Artha, a warm, intelligent personal financial mentor for Indian users.
You speak like a trusted friend who happens to be a certified financial planner and CA.
Rules:
- Keep responses under 3 sentences unless the user asks for a detailed plan
- Use Indian financial context: SIP, PPF, NPS, ELSS, HRA, 80C, 80D
- Always use ₹ symbol and Indian number format (L, Cr)
- Never recommend specific stocks or crypto
- Never calculate tax yourself — defer to the Tax Engine
- End advice with: "This is financial education, not SEBI advice"
- Be warm, encouraging, never judgmental
"""

ARTHA_SYSTEM_PROMPT_HI = """
आप अर्था हैं, एक गर्मजोशी से भरे, बुद्धिमान व्यक्तिगत वित्तीय सलाहकार।
आप हिंदी में बात करें।
नियम:
- भारतीय वित्तीय शब्दों का उपयोग करें: SIP, PPF, NPS, ELSS, 80C, 80D
- हमेशा ₹ चिह्न और भारतीय संख्या प्रारूप (L, Cr) का उपयोग करें
- कभी भी स्टॉक या क्रिप्टो की सिफारिश न करें
- 3 वाक्यों से कम में जवाब दें
"""

ARTHA_SYSTEM_PROMPT_TA = """
நீங்கள் அர்தா, ஒரு அன்பான, புத்திசாலி தனிப்பட்ட நிதி வழிகாட்டி.
தமிழில் பதில் சொல்லுங்கள்.
விதிகள்:
- இந்திய நிதி சொற்களை பயன்படுத்துங்கள்: SIP, PPF, NPS, ELSS, 80C
- எப்போதும் ₹ குறியீடு பயன்படுத்துங்கள்
- 3 வாக்கியங்களுக்கு குறைவாக பதிலளிக்கவும்
"""

# ── Rate-limit queue ──────────────────────────────────────────────────────────
_lock = threading.Lock()
_last_request_time = 0.0
_MIN_INTERVAL_SECS = 1.5   # max ~40 RPM on free tier

_FALLBACKS = {
    'insurance':   ('Having zero life cover at your income level is the '
                    'highest financial risk you carry today. A ₹1.5Cr term plan '
                    'costs only ₹1,200/mo — fix this first. This is financial education, not SEBI advice.'),
    'fire':        ('Starting a ₹5,000/mo SIP in a Nifty 50 index fund today '
                    'grows to ₹12L in 10 years at 12% CAGR. The earlier you '
                    'start, the less you need to invest. This is financial education, not SEBI advice.'),
    'tax':         ('You are not fully utilising your 80C deduction limit. '
                    'Investing ₹12,500/month in ELSS saves ₹46,800/year in tax '
                    'while also building wealth. This is financial education, not SEBI advice.'),
    'emergency':   ('Your emergency fund should cover 6 months of expenses. '
                    'Keep it in a liquid fund or high-yield savings account — '
                    'never in equity. This is financial education, not SEBI advice.'),
    'debt':        ('Keep your total EMI below 40% of monthly income to maintain '
                    'healthy debt ratios. Any surplus after EMIs should go into '
                    'a SIP before lifestyle upgrades. This is financial education, not SEBI advice.'),
    'default':     ('This area of your finances needs attention. Focus on one '
                    'improvement at a time — small consistent actions compound '
                    'significantly. This is financial education, not SEBI advice.'),
}

def _get_fallback(prompt: str) -> str:
    p = prompt.lower()
    if 'insurance' in p: return _FALLBACKS['insurance']
    if 'fire' in p or 'retire' in p: return _FALLBACKS['fire']
    if 'tax' in p or '80c' in p: return _FALLBACKS['tax']
    if 'emergency' in p: return _FALLBACKS['emergency']
    if 'debt' in p or 'emi' in p: return _FALLBACKS['debt']
    return _FALLBACKS['default']

def _call_gemini(prompt: str, max_retries: int = 3) -> str:
    global _last_request_time
    for attempt in range(max_retries):
        with _lock:
            now = time.time()
            wait = _MIN_INTERVAL_SECS - (now - _last_request_time)
            if wait > 0:
                time.sleep(wait)
            _last_request_time = time.time()

        try:
            resp = _client.models.generate_content(
                model=_MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.7),
            )
            return resp.text
        except Exception as e:
            err = str(e)
            if '429' in err or 'quota' in err.lower() or 'resource_exhausted' in err.lower():
                backoff = (attempt + 1) * 5
                time.sleep(backoff)
                continue
            # Non-rate-limit error — fail immediately
            raise e

    return _get_fallback(prompt)


def get_artha_response(message: str, conversation_history: list,
                       user_context: dict, language: str = 'en') -> str:
    if language == 'hi':
        system = ARTHA_SYSTEM_PROMPT_HI
        lang_prefix = 'हिंदी में जवाब दें। '
    elif language == 'ta':
        system = ARTHA_SYSTEM_PROMPT_TA
        lang_prefix = 'தமிழில் பதில் சொல்லுங்கள். '
    else:
        system = ARTHA_SYSTEM_PROMPT_EN
        lang_prefix = ''

    context_str = f"""
User Financial Context:
- Monthly Income: ₹{user_context.get('monthly_salary', user_context.get('monthly_income', 'Unknown'))}
- Monthly Expenses: ₹{user_context.get('monthly_expense', 'Unknown')}
- Current Savings: ₹{user_context.get('current_savings', 'Unknown')}
- Has Insurance: {user_context.get('has_term_insurance', 'Unknown')}
- Primary Goal: {user_context.get('financial_goal', user_context.get('primary_goal', 'Not set'))}
- Risk Appetite: {user_context.get('risk_appetite', 'moderate')}
"""

    history_str = '\n'.join([
        f"{'Artha' if m.get('role') == 'model' else 'User'}: {m.get('content', '')}"
        for m in conversation_history[-10:]
    ])

    full_prompt = (
        f"{system}\n\n{context_str}\n\n"
        f"Conversation:\n{history_str}\n\n"
        f"User: {lang_prefix}{message}\n\nArtha:"
    )

    return _call_gemini(full_prompt)
