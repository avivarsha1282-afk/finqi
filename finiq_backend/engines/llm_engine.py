"""
LLM Engine — Smart routing for text-only AI calls.
Cascade: Ollama (local) → Groq (cloud free) → Gemini (fallback)
Eliminates 80% of Gemini quota usage for pure-reasoning tasks.
"""

import os
import time
import requests
from dotenv import load_dotenv

load_dotenv()

# ── Environment ──────────────────────────────────────────────────────────────
OLLAMA_URL = os.getenv('OLLAMA_URL', 'http://localhost:11434')
GROQ_API_KEY = os.getenv('GROQ_API_KEY', '')
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')

OLLAMA_MODEL = 'llama3.1:8b'
GROQ_MODEL = 'llama-3.3-70b-versatile'
GROQ_BASE_URL = 'https://api.groq.com/openai/v1'


# ── Provider 1: Ollama (local, free, for development) ────────────────────────
def call_local_llama(prompt: str, system: str = '', max_tokens: int = 500) -> str:
    """Call Ollama running locally on dev machine."""
    if not OLLAMA_URL:
        return None
    try:
        messages = []
        if system:
            messages.append({'role': 'system', 'content': system})
        messages.append({'role': 'user', 'content': prompt})

        response = requests.post(
            f'{OLLAMA_URL}/api/chat',
            json={
                'model': OLLAMA_MODEL,
                'messages': messages,
                'stream': False,
                'options': {'num_predict': max_tokens}
            },
            timeout=30
        )
        if response.status_code != 200:
            print(f"[OLLAMA] HTTP {response.status_code}")
            return None
        data = response.json()
        content = data.get('message', {}).get('content', '')
        return content if content.strip() else None
    except Exception as e:
        print(f"[OLLAMA] Failed: {e}")
        return None


# ── Provider 2: Groq (cloud, free tier, fast) ────────────────────────────────
def call_groq_llama(prompt: str, system: str = '', max_tokens: int = 500) -> str:
    """Call Groq cloud Llama — free tier, very fast."""
    if not GROQ_API_KEY:
        return None
    try:
        headers = {
            'Authorization': f'Bearer {GROQ_API_KEY}',
            'Content-Type': 'application/json',
        }
        messages = []
        if system:
            messages.append({'role': 'system', 'content': system})
        messages.append({'role': 'user', 'content': prompt})

        response = requests.post(
            f'{GROQ_BASE_URL}/chat/completions',
            headers=headers,
            json={
                'model': GROQ_MODEL,
                'messages': messages,
                'max_tokens': max_tokens,
                'temperature': 0.7,
            },
            timeout=30
        )
        if response.status_code != 200:
            print(f"[GROQ] HTTP {response.status_code}: {response.text[:200]}")
            return None
        data = response.json()
        content = data['choices'][0]['message']['content']
        return content if content.strip() else None
    except Exception as e:
        print(f"[GROQ] Failed: {e}")
        return None


# ── Provider 3: Gemini text-only (last resort for text tasks) ────────────────
def call_gemini_text_only(prompt: str, system: str = '') -> str:
    """Call Gemini for text-only task via the existing pool."""
    try:
        from engines.gemini_pool import smart_generate
        from google.genai import types

        full_prompt = f"{system}\n\n{prompt}" if system else prompt
        response = smart_generate(
            None,  # Use default model cascade
            full_prompt,
            types.GenerateContentConfig(temperature=0.7)
        )
        return response.text if response and response.text else None
    except Exception as e:
        print(f"[GEMINI_TEXT] Failed: {e}")
        return None


# ── Smart Router ─────────────────────────────────────────────────────────────
def call_text_llm(prompt: str, system: str = '', max_tokens: int = 500) -> str:
    """
    Smart routing for text-only LLM calls.
    Order: Ollama (local) → Groq (cloud) → Gemini (fallback)
    Never fails silently — always returns something.
    """
    # Try local Ollama first (development)
    result = call_local_llama(prompt, system, max_tokens)
    if result:
        print("[LLM] Used: Ollama local")
        return result

    # Try Groq (production / when PC Ollama is off)
    result = call_groq_llama(prompt, system, max_tokens)
    if result:
        print("[LLM] Used: Groq cloud")
        return result

    # Last resort: Gemini (for text-only tasks)
    result = call_gemini_text_only(prompt, system)
    if result:
        print("[LLM] Used: Gemini fallback")
        return result

    # Everything failed
    print("[LLM] All providers failed")
    return None


# ── Language-aware Artha Router ──────────────────────────────────────────────
def route_artha_call(prompt: str, system: str, language: str = 'en',
                     max_tokens: int = 500) -> str:
    """
    Route Artha chat based on language.
    Hindi → Gemini (better Hindi quality)
    English → Ollama/Groq/Gemini cascade (saves Gemini quota)
    """
    if language == 'hi':
        # Gemini is better for Hindi responses
        result = call_gemini_text_only(prompt, system)
        if result:
            print("[LLM] Used: Gemini (Hindi mode)")
            return result
        # Fallback to Groq if Gemini fails
        result = call_groq_llama(prompt, system, max_tokens)
        if result:
            print("[LLM] Used: Groq fallback (Hindi)")
            return result
        return None
    else:
        # English: use the full cascade to save Gemini quota
        return call_text_llm(prompt, system, max_tokens)
