"""
Smart Buy Lens — Production API

Endpoints:
  POST /smart-buy/analyse/single   – Analyse one product image
  POST /smart-buy/analyse/compare  – Compare two product images
  POST /smart-buy/save             – Save analysis report to MongoDB
  GET  /smart-buy/history          – Get user's analysis history
  DELETE /smart-buy/report/<id>    – Delete a saved report

Security:
  - Financial data used for computation only, never logged
  - Images never stored, only MD5 hash for dedup/caching
  - Rate limiting: 10/day, 50/month per user
  - All Gemini errors logged without PII
"""

import base64
import hashlib
import json
import os
import traceback
from datetime import datetime, timedelta

from bson import ObjectId
from flask import Blueprint, request, jsonify

from models.firebase import verify_token
from models.user_model import get_user_by_uid

smart_buy_bp = Blueprint('smart_buy', __name__)

# ── MongoDB collections ─────────────────────────────────────────
try:
    from models.database import db
    smart_buy_reports = db['smart_buy_reports']
    smart_buy_cache = db['smart_buy_cache']
    smart_buy_usage = db['smart_buy_usage']

    # Ensure indexes (idempotent)
    smart_buy_reports.create_index([('userId', 1), ('createdAt', -1)])
    smart_buy_cache.create_index('expiresAt', expireAfterSeconds=0)  # TTL index
    smart_buy_cache.create_index([('userId', 1), ('imageHash', 1)])
    smart_buy_usage.create_index([('userId', 1), ('date', 1)], unique=True)
except Exception as e:
    print(f'Smart Buy DB setup warning: {e}')
    smart_buy_reports = None
    smart_buy_cache = None
    smart_buy_usage = None


# ── Auth helper ──────────────────────────────────────────────────
def _uid_from_request():
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None, (jsonify({'error': 'No authorization token'}), 401)
    token = auth_header.replace('Bearer ', '') if auth_header.startswith('Bearer ') else auth_header
    decoded = verify_token(token)
    if not decoded:
        return None, (jsonify({'error': 'Invalid or expired token'}), 401)
    return decoded.get('uid'), None


# ── Rate limiter ─────────────────────────────────────────────────
def _check_rate_limit(uid):
    """Returns (allowed: bool, message: str)"""
    if smart_buy_usage is None:
        return True, ''

    today = datetime.utcnow().strftime('%Y-%m-%d')
    month = datetime.utcnow().strftime('%Y-%m')

    # Daily check
    daily = smart_buy_usage.find_one({'userId': uid, 'date': today})
    if daily and daily.get('count', 0) >= 10:
        return False, 'Daily limit reached (10/day). Try again tomorrow.'

    # Monthly check
    month_start = datetime.utcnow().replace(day=1, hour=0, minute=0, second=0)
    pipeline = [
        {'$match': {'userId': uid, 'date': {'$gte': month_start.strftime('%Y-%m-%d')}}},
        {'$group': {'_id': None, 'total': {'$sum': '$count'}}}
    ]
    monthly = list(smart_buy_usage.aggregate(pipeline))
    if monthly and monthly[0].get('total', 0) >= 50:
        return False, 'Monthly limit reached (50/month). Resets next month.'

    return True, ''


def _increment_usage(uid):
    """Increment daily usage counter."""
    if smart_buy_usage is None:
        return
    today = datetime.utcnow().strftime('%Y-%m-%d')
    smart_buy_usage.update_one(
        {'userId': uid, 'date': today},
        {'$inc': {'count': 1}},
        upsert=True
    )


# ── Input validation ─────────────────────────────────────────────
def _validate_financial_inputs(data):
    """Validate financial profile data. Returns (valid, errors)."""
    errors = {}
    income = data.get('monthlyIncome', 0)
    expenses = data.get('monthlyExpenses', 0)
    savings = data.get('currentSavings', 0)

    if not isinstance(income, (int, float)) or income <= 0:
        errors['monthlyIncome'] = 'Must be a positive number'
    elif income > 500_000_000:
        errors['monthlyIncome'] = 'Value exceeds maximum (₹5 Crore/month)'

    if not isinstance(expenses, (int, float)) or expenses <= 0:
        errors['monthlyExpenses'] = 'Must be a positive number'
    elif expenses > income and income > 0:
        errors['monthlyExpenses'] = 'Cannot exceed monthly income'

    if not isinstance(savings, (int, float)) or savings < 0:
        errors['currentSavings'] = 'Must be zero or positive'
    elif savings > 500_000_000:
        errors['currentSavings'] = 'Value exceeds maximum (₹50 Crore)'

    return len(errors) == 0, errors


def _validate_image(image_b64):
    """Validate base64 image. Returns (valid, error_msg)."""
    if not image_b64:
        return False, 'No image provided'
    try:
        decoded = base64.b64decode(image_b64)
        if len(decoded) > 4 * 1024 * 1024:  # 4MB
            return False, 'Image too large (max 4MB)'
        return True, ''
    except Exception:
        return False, 'Invalid image data'


def _image_hash(image_b64):
    """MD5 hash of the image for caching/dedup. Never stores the image."""
    return hashlib.md5(image_b64.encode('utf-8')).hexdigest()


# ── Cache check ──────────────────────────────────────────────────
def _get_cached_result(uid, img_hash):
    """Check if we have a cached result for this image hash within 24h."""
    if smart_buy_cache is None:
        return None
    cached = smart_buy_cache.find_one({
        'userId': uid,
        'imageHash': img_hash,
        'expiresAt': {'$gt': datetime.utcnow()}
    })
    if cached:
        cached.pop('_id', None)
        cached.pop('userId', None)
        cached.pop('imageHash', None)
        cached.pop('expiresAt', None)
        return cached.get('result')
    return None


def _set_cached_result(uid, img_hash, result):
    """Cache a result for 24 hours."""
    if smart_buy_cache is None:
        return
    smart_buy_cache.update_one(
        {'userId': uid, 'imageHash': img_hash},
        {'$set': {
            'result': result,
            'expiresAt': datetime.utcnow() + timedelta(hours=24)
        }},
        upsert=True
    )


# ── Error logging (no PII) ──────────────────────────────────────
def _log_error(endpoint, uid, error_type, error_msg):
    """Log errors without any personal financial data."""
    uid_hash = hashlib.sha256(uid.encode()).hexdigest()[:16] if uid else 'unknown'
    print(f'[SMART_BUY_ERROR] {datetime.utcnow().isoformat()} '
          f'endpoint={endpoint} user={uid_hash} '
          f'type={error_type} msg={error_msg}')


# ── Income corruption detection ──────────────────────────────────
MAX_REALISTIC_INCOME = 500_000_000   # ₹5 Crore/month
MAX_REALISTIC_SAVINGS = 500_000_000  # ₹50 Crore

def _sanitise_financials(data):
    """Returns (income, expenses, savings, is_corrupted)."""
    income = float(data.get('monthlyIncome', 0))
    expenses = float(data.get('monthlyExpenses', 0))
    savings = float(data.get('currentSavings', 0))
    corrupted = False

    if income > MAX_REALISTIC_INCOME or savings > MAX_REALISTIC_SAVINGS:
        income = 0
        expenses = 0
        savings = 0
        corrupted = True

    return income, expenses, savings, corrupted


# ── JSON parser (handles markdown fences, grounding metadata) ────
import re as _re

def _parse_json_safely(text):
    """Extract and parse JSON from Gemini response text.
    Handles markdown code fences, grounding metadata, etc."""
    if not text:
        return {}
    text = _re.sub(r'```(?:json)?\n?(.*?)\n?```', r'\1', text, flags=_re.DOTALL)
    text = text.strip()
    start = text.find('{')
    end = text.rfind('}') + 1
    if start == -1 or end == 0:
        return {}
    try:
        return json.loads(text[start:end])
    except json.JSONDecodeError:
        return {}


# ── Gemini call helper (IMAGE — JSON mode, no search) ────────────
def _call_gemini(prompt, images_b64):
    """Call Gemini with intelligent model fallback & key rotation."""
    from google.genai import types
    from engines.gemini_pool import smart_generate

    contents = []
    for img_b64 in images_b64:
        contents.append(types.Part.from_bytes(
            data=base64.b64decode(img_b64),
            mime_type='image/jpeg'
        ))
    contents.append(types.Part.from_text(text=prompt))

    # Use DEFAULT_MODEL_CASCADE from pool (2.5-flash has most quota)

    response = smart_generate(
        contents=contents,
        config=types.GenerateContentConfig(
            temperature=0.2,
            response_mime_type='application/json',
        )
    )

    result_text = response.text.strip() if response and response.text else ''
    parsed = _parse_json_safely(result_text)
    if parsed:
        return parsed
        
    raise Exception("Parsed empty or invalid response from AI pool")


# ── Gemini call helper (TEXT — with Google Search grounding) ─────
def _call_gemini_text(prompt, use_search=True):
    """Call Gemini with text-only prompt and API Key rotation."""
    from google.genai import types
    from engines.gemini_pool import smart_generate

    config_kwargs = {'temperature': 0.3}
    if use_search:
        try:
            search_tool = types.Tool(google_search=types.GoogleSearch())
            config_kwargs['tools'] = [search_tool]
        except Exception as e:
            print(f'Search grounding not available: {e}')

    models_to_try = None  # Uses DEFAULT_MODEL_CASCADE from pool
    
    try:
        response = smart_generate(models_to_try, prompt, types.GenerateContentConfig(**config_kwargs))
        return _parse_json_safely(response.text.strip() if response and response.text else '')
    except Exception as e:
        print(f"[SMART_BUY_TEXT] Text pool failed: {e}")
        return {}


# ── Online search step (runs after image analysis) ───────────────
import threading

def _search_online(product_name, brand, category, price):
    """Step 2: Text-only Gemini call with Google Search grounding.
    Returns online listings and similar products.
    15-second timeout — never blocks the main result."""
    try:
        price_str = f'around ₹{price:,.0f}' if price else ''
        search_prompt = f"""Search Google Shopping for "{brand} {product_name}" in India.

Find and return:
1. The exact product listing URL on Amazon India (amazon.in), Flipkart (flipkart.com), and Meesho (meesho.com) if available
2. Current selling price on each platform
3. User ratings and review count on each platform
4. Any "Best Seller", "Amazon's Choice", or deal badges
5. Three similar or alternative products in the {category} category {price_str}
   Include their URLs, prices, and ratings

Return ONLY this JSON:
{{
  "listings": [
    {{
      "platform": "Amazon",
      "url": "https://amazon.in/...",
      "price": 329,
      "originalPrice": 499,
      "discount": "34% off",
      "rating": 4.3,
      "reviewCount": 2100,
      "badge": "Amazon's Choice",
      "inStock": true
    }}
  ],
  "similarProducts": [
    {{
      "name": "string",
      "brand": "string",
      "price": 299,
      "url": "https://amazon.in/...",
      "platform": "Amazon",
      "rating": 4.1,
      "whyConsider": "More affordable, similar specs"
    }}
  ],
  "priceInsight": {{
    "isGoodDeal": true,
    "dealReason": "34% below MRP, competitive price"
  }}
}}
Return ONLY valid JSON. No markdown. No explanation."""

        result = [{}]
        def _do_search():
            result[0] = _call_gemini_text(search_prompt, use_search=True)

        thread = threading.Thread(target=_do_search)
        thread.start()
        thread.join(timeout=15)  # 15-second timeout

        if thread.is_alive():
            print('[SMART_BUY] Search step timed out after 15s')
            return {'listings': [], 'similarProducts': [], 'priceInsight': None}

        return result[0] if result[0] else {'listings': [], 'similarProducts': [], 'priceInsight': None}

    except Exception as e:
        print(f'[SMART_BUY] Search step failed: {e}')
        return {'listings': [], 'similarProducts': [], 'priceInsight': None}


# ═══════════════════════════════════════════════════════════════════
# ENDPOINT 1: Analyse Single Product
# ═══════════════════════════════════════════════════════════════════
@smart_buy_bp.route('/smart-buy/analyse/single', methods=['POST'])
def analyse_single():
    uid, err = _uid_from_request()
    if err:
        return err

    # Rate limit
    allowed, msg = _check_rate_limit(uid)
    if not allowed:
        return jsonify({'error': msg}), 429

    data = request.json or {}

    # Validate image first (cheap check)
    image_b64 = data.get('image')
    img_valid, img_error = _validate_image(image_b64)
    if not img_valid:
        return jsonify({'error': img_error}), 400

    img_hash = _image_hash(image_b64)

    # Check cache
    cached = _get_cached_result(uid, img_hash)
    if cached:
        return jsonify({'success': True, 'analysis': cached, 'cached': True}), 200

    # Sanitise financials (detect corruption)
    income, expenses, savings, data_corrupted = _sanitise_financials(data)
    surplus = max(0, income - expenses)

    # Build financial section of prompt
    if data_corrupted:
        finance_section = """USER FINANCIAL PROFILE: DATA CORRUPTED
The user's financial profile data appears corrupted. Do NOT make affordability
claims based on specific numbers. Give a general quality and value analysis only.
Set affordabilityLevel to 'UNKNOWN'.
Set arthaInsight to: 'Update your financial profile in FinIQ settings to get personalised advice.'"""
    else:
        finance_section = f"""USER FINANCIAL PROFILE:
- Monthly Income: ₹{income:,.0f}
- Monthly Expenses: ₹{expenses:,.0f}
- Monthly Surplus: ₹{surplus:,.0f}
- Current Savings: ₹{savings:,.0f}"""

    prompt = f"""You are a world-class consumer product analyst and certified financial advisor for the Indian market.
Analyse the product in this image.

{finance_section}

YOUR TASK:
1. Identify the product (name, brand, category, price if visible)
2. Detect category: ELECTRONICS | GROCERY | PERSONAL_CARE | APPLIANCE | CLOTHING | FOOD | CLEANING | OTHER
3. Analyse product quality: brand reputation, ingredients/specs visible, packaging quality, red flags
4. Calculate affordability (skip if profile corrupted):
   - COMFORTABLE if price < 5% of monthly surplus
   - MANAGEABLE if price is 5-20% of monthly surplus
   - STRETCH if price is 20-50% of monthly surplus
   - SKIP if price > 50% of monthly surplus OR surplus <= 0
   - UNKNOWN if user profile is corrupted
   IMPORTANT: If monthly surplus is positive and product price is clearly affordable, NEVER return SKIP.
5. Value for Money score (1-10)
6. Overall verdict: BUY | CONSIDER | SKIP
7. Artha financial tip — 1 sentence with actual ₹ numbers (skip numbers if profile corrupted)
8. Suggest 2 alternatives only if verdict is SKIP or CONSIDER

ONLINE RESEARCH REQUIRED:
After identifying the product from the image, search online for:
1. The exact product listing on Amazon India, Flipkart, and Meesho
2. Current price on each platform
3. User ratings and review count on each platform
4. 2-3 similar/alternative products in the same category and price range
5. Whether the current price is a good deal compared to historical prices
Include real URLs in your response. Format URLs as complete links (https://...).
If you cannot find the exact product, search for the category + brand + key specs.

Return ONLY this JSON:
{{
  "productName": "string",
  "brand": "string",
  "category": "string",
  "detectedPrice": null or number,
  "verdict": "BUY|CONSIDER|SKIP",
  "verdictReason": "2 sentences max",
  "affordabilityLevel": "COMFORTABLE|MANAGEABLE|STRETCH|SKIP|UNKNOWN",
  "affordabilityPercent": number,
  "valueForMoneyScore": number,
  "qualityScore": number,
  "qualityBreakdown": {{
    "brandReputation": "EXCELLENT|GOOD|AVERAGE|UNKNOWN",
    "buildOrIngredients": "string",
    "packaging": "PREMIUM|STANDARD|BASIC",
    "redFlags": []
  }},
  "keySpecs": [
    {{"label": "string", "value": "string"}}
  ],
  "pros": ["string"],
  "cons": ["string"],
  "arthaInsight": "string with ₹ numbers",
  "alternatives": [
    {{"name": "string", "priceRange": "string", "reason": "string"}}
  ]
}}"""

    try:
        # Step 1: Image analysis (JSON mode, no search)
        result = _call_gemini(prompt, [image_b64])

        # Step 2: Online search (grounding, 15s timeout, non-blocking)
        product_name = result.get('productName', '')
        brand = result.get('brand', '')
        category = result.get('category', '')
        price = result.get('detectedPrice', 0)

        if product_name and brand:
            search_data = _search_online(product_name, brand, category, price or 0)
            result['onlineListings'] = search_data.get('listings', [])
            result['similarProducts'] = search_data.get('similarProducts', [])
            result['priceHistory'] = search_data.get('priceInsight') or {
                'isGoodDeal': False, 'dealReason': '', 'lowestEver': None
            }

        _increment_usage(uid)
        _set_cached_result(uid, img_hash, result)

        return jsonify({
            'success': True,
            'analysis': result,
            'imageHash': img_hash,
            'cached': False,
            'profileDataCorrupted': data_corrupted,
        }), 200

    except json.JSONDecodeError as e:
        _log_error('analyse/single', uid, 'JSON_PARSE', str(e))
        return jsonify({
            'success': False,
            'error': 'AI returned invalid format. Try a clearer photo.',
        }), 200

    except Exception as e:
        err_str = str(e)
        _log_error('analyse/single', uid, type(e).__name__, err_str[:200])
        if '429' in err_str or 'quota' in err_str.lower():
            return jsonify({
                'success': False,
                'error': 'Google AI free tier limit reached (15 scans/min). Please wait 60 seconds and try again.',
            }), 200
            
        return jsonify({
            'success': False,
            'error': 'Could not analyse the product. Try again with a clearer photo.',
        }), 200


# ═══════════════════════════════════════════════════════════════════
# ENDPOINT 2: Compare Two Products
# ═══════════════════════════════════════════════════════════════════
@smart_buy_bp.route('/smart-buy/analyse/compare', methods=['POST'])
def analyse_compare():
    uid, err = _uid_from_request()
    if err:
        return err

    allowed, msg = _check_rate_limit(uid)
    if not allowed:
        return jsonify({'error': msg}), 429

    data = request.json or {}

    image1_b64 = data.get('image1')
    image2_b64 = data.get('image2')

    for idx, img in enumerate([image1_b64, image2_b64], 1):
        img_valid, img_error = _validate_image(img)
        if not img_valid:
            return jsonify({'error': f'Product {idx}: {img_error}'}), 400

    # Combined hash for caching
    combined_hash = _image_hash(image1_b64 + image2_b64)
    cached = _get_cached_result(uid, combined_hash)
    if cached:
        return jsonify({'success': True, 'analysis': cached, 'cached': True}), 200

    income, expenses, savings, data_corrupted = _sanitise_financials(data)
    surplus = max(0, income - expenses)

    prompt = f"""You are a world-class consumer product analyst and certified financial advisor for the Indian market.
You are given TWO product images. The user wants to know which one to buy.
They have no technical knowledge. Explain everything simply but completely.

USER FINANCIAL PROFILE:
- Monthly Income: ₹{income:,.0f}
- Monthly Expenses: ₹{expenses:,.0f}
- Monthly Surplus: ₹{surplus:,.0f}
- Current Savings: ₹{savings:,.0f}

THE USER'S PROBLEM:
They are in a store or browsing online. They see two products, possibly at similar prices.
They need to know: which one gives better value for this user's budget and needs?

YOUR TASK:
1. Identify both products fully
2. Score each on 5 dimensions (0-10): Value for Money, Build Quality, Brand Trust, Features, Long-term Worth
3. Create a comparison spec table with every visible spec/feature
4. Declare an overall winner with clear reasoning
5. Calculate affordability for each based on the financial profile
6. Give a final Artha verdict with specific ₹ numbers

The FIRST image is Product 1. The SECOND image is Product 2.

Return ONLY this JSON:
{{
  "category": "string",
  "product1": {{
    "name": "string",
    "brand": "string",
    "detectedPrice": null or number,
    "scores": {{
      "valueForMoney": number,
      "buildQuality": number,
      "brandTrust": number,
      "featuresScore": number,
      "longTermWorth": number,
      "overall": number
    }},
    "pros": ["string"],
    "cons": ["string"],
    "affordabilityLevel": "COMFORTABLE|MANAGEABLE|STRETCH|SKIP"
  }},
  "product2": {{
    "name": "string",
    "brand": "string",
    "detectedPrice": null or number,
    "scores": {{
      "valueForMoney": number,
      "buildQuality": number,
      "brandTrust": number,
      "featuresScore": number,
      "longTermWorth": number,
      "overall": number
    }},
    "pros": ["string"],
    "cons": ["string"],
    "affordabilityLevel": "COMFORTABLE|MANAGEABLE|STRETCH|SKIP"
  }},
  "comparisonTable": [
    {{
      "attribute": "string",
      "product1Value": "string",
      "product2Value": "string",
      "winner": 0 or 1 or 2
    }}
  ],
  "winner": 1 or 2,
  "winnerReason": "3 sentences, plain English, mention specific features and prices",
  "arthaInsight": "string with actual ₹ numbers, compare to their surplus",
  "bothAffordable": true or false
}}"""

    try:
        # Step 1: Compare analysis (JSON mode, no search)
        result = _call_gemini(prompt, [image1_b64, image2_b64])

        # Step 2: Online search for both products
        p1_name = result.get('product1', {}).get('name', '')
        p1_brand = result.get('product1', {}).get('brand', '')
        p1_price = result.get('product1', {}).get('detectedPrice', 0)
        p2_name = result.get('product2', {}).get('name', '')
        p2_brand = result.get('product2', {}).get('brand', '')
        p2_price = result.get('product2', {}).get('detectedPrice', 0)
        cat = result.get('category', '')

        if p1_name and p1_brand:
            s1 = _search_online(p1_name, p1_brand, cat, p1_price or 0)
            result.setdefault('product1', {})['onlineListings'] = s1.get('listings', [])

        if p2_name and p2_brand:
            s2 = _search_online(p2_name, p2_brand, cat, p2_price or 0)
            result.setdefault('product2', {})['onlineListings'] = s2.get('listings', [])

        _increment_usage(uid)
        _set_cached_result(uid, combined_hash, result)

        return jsonify({
            'success': True,
            'analysis': result,
            'imageHash1': _image_hash(image1_b64),
            'imageHash2': _image_hash(image2_b64),
            'cached': False,
            'profileDataCorrupted': data_corrupted,
        }), 200

    except json.JSONDecodeError as e:
        _log_error('analyse/compare', uid, 'JSON_PARSE', str(e))
        return jsonify({
            'success': False,
            'error': 'AI returned invalid comparison. Try clearer photos.',
        }), 200

    except Exception as e:
        err_str = str(e)
        _log_error('analyse/compare', uid, type(e).__name__, err_str[:200])
        if '429' in err_str or 'quota' in err_str.lower():
            return jsonify({
                'success': False,
                'error': 'Google AI free tier limit reached. Please wait 60 seconds and try again.',
            }), 200
            
        return jsonify({
            'success': False,
            'error': 'Could not compare products. Try again.',
        }), 200


# ═══════════════════════════════════════════════════════════════════
# ENDPOINT 3: Save Report to MongoDB
# ═══════════════════════════════════════════════════════════════════
@smart_buy_bp.route('/smart-buy/save', methods=['POST'])
def save_report():
    uid, err = _uid_from_request()
    if err:
        return err

    if smart_buy_reports is None:
        return jsonify({'error': 'Storage unavailable'}), 503

    data = request.json or {}
    report = {
        'userId': uid,
        'mode': data.get('mode', 'single'),
        'createdAt': datetime.utcnow(),
        'product1': data.get('product1'),
        'product2': data.get('product2'),
        'winner': data.get('winner'),
        'winnerReason': data.get('winnerReason'),
        'financialSnapshot': data.get('financialSnapshot', {}),
    }

    result = smart_buy_reports.insert_one(report)
    return jsonify({
        'success': True,
        'reportId': str(result.inserted_id)
    }), 201


# ═══════════════════════════════════════════════════════════════════
# ENDPOINT 4: Get History
# ═══════════════════════════════════════════════════════════════════
@smart_buy_bp.route('/smart-buy/history', methods=['GET'])
def get_history():
    uid, err = _uid_from_request()
    if err:
        return err

    if smart_buy_reports is None:
        return jsonify({'reports': []}), 200

    limit = min(int(request.args.get('limit', 20)), 50)
    cursor = smart_buy_reports.find(
        {'userId': uid},
        {'_id': 1, 'mode': 1, 'createdAt': 1, 'product1.name': 1,
         'product1.verdict': 1, 'product2.name': 1, 'winner': 1}
    ).sort('createdAt', -1).limit(limit)

    reports = []
    for doc in cursor:
        doc['_id'] = str(doc['_id'])
        doc['createdAt'] = doc['createdAt'].isoformat() if isinstance(doc['createdAt'], datetime) else str(doc['createdAt'])
        reports.append(doc)

    return jsonify({'reports': reports}), 200


# ═══════════════════════════════════════════════════════════════════
# ENDPOINT 5: Delete Report
# ═══════════════════════════════════════════════════════════════════
@smart_buy_bp.route('/smart-buy/report/<report_id>', methods=['DELETE'])
def delete_report(report_id):
    uid, err = _uid_from_request()
    if err:
        return err

    if smart_buy_reports is None:
        return jsonify({'error': 'Storage unavailable'}), 503

    try:
        result = smart_buy_reports.delete_one({
            '_id': ObjectId(report_id),
            'userId': uid  # Ensure user only deletes own reports
        })
        if result.deleted_count == 0:
            return jsonify({'error': 'Report not found'}), 404
        return jsonify({'success': True}), 200
    except Exception:
        return jsonify({'error': 'Invalid report ID'}), 400
