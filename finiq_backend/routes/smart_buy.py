import base64
from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.user_model import get_user_by_uid

smart_buy_bp = Blueprint('smart_buy', __name__)


def _uid_from_request():
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None, (jsonify({'error': 'No authorization token'}), 401)
    decoded = verify_token(auth_header)
    if not decoded:
        return None, (jsonify({'error': 'Invalid token'}), 401)
    return decoded.get('uid'), None


@smart_buy_bp.route('/smart-buy/compare', methods=['POST'])
def compare_product():
    """Multimodal Gemini: User sends product photo → AI compares alternatives."""
    uid, err = _uid_from_request()
    if err:
        return err

    # Get user context for budget awareness
    user = get_user_by_uid(uid)
    profile = user.get('profile', {}) if user else {}
    monthly_income = float(profile.get('monthly_salary', 0))
    monthly_expense = float(profile.get('monthly_expense', 0))
    monthly_surplus = max(0, monthly_income - monthly_expense)

    # Get image data
    image_data = request.json.get('image_base64')
    product_name = request.json.get('product_name', 'this product')
    budget_max = request.json.get('budget_max', 0)

    if not image_data:
        return jsonify({'error': 'No image provided'}), 400

    prompt = f"""You are FinIQ Smart Buy Lens — an AI shopping advisor for Indian consumers.

USER FINANCIAL CONTEXT:
Monthly Income: ₹{monthly_income:,.0f}
Monthly Surplus (after expenses): ₹{monthly_surplus:,.0f}
Budget Limit: {'₹' + f'{budget_max:,.0f}' if budget_max > 0 else 'Not specified'}

TASK: Analyse the product in this image and provide a smart buying recommendation.

Return ONLY valid JSON with this EXACT structure:
{{
    "product_identified": "Name and brand of the product",
    "estimated_price": "₹XX,XXX",
    "verdict": "BUY" or "WAIT" or "SKIP",
    "verdict_reason": "2-sentence explanation based on their income",
    "affordability_score": 1-10,
    "affordability_label": "e.g. 'Easily affordable' or 'Stretch purchase'",
    "alternatives": [
        {{
            "name": "Alternative product name",
            "price": "₹XX,XXX",
            "why": "1-sentence reason to consider"
        }},
        {{
            "name": "Another alternative",
            "price": "₹XX,XXX",
            "why": "1-sentence reason"
        }}
    ],
    "smart_tip": "One sentence financial tip about this purchase category",
    "wait_suggestion": "If WAIT verdict: when/why to wait (e.g. 'Flipkart Big Billion Days in October')"
}}"""

    try:
        from google import genai
        import os
        client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))

        # Decode base64 image
        image_bytes = base64.b64decode(image_data)

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[
                prompt,
                {'inline_data': {'mime_type': 'image/jpeg', 'data': image_data}}
            ]
        )

        result_text = response.text.strip()
        # Strip markdown if present
        if result_text.startswith('```'):
            result_text = result_text.split('```')[1]
            if result_text.startswith('json'):
                result_text = result_text[4:]

        import json
        result = json.loads(result_text.strip())

        return jsonify({
            'success': True,
            'analysis': result
        }), 200

    except Exception as e:
        print(f'Smart Buy analysis failed: {e}')
        return jsonify({
            'success': False,
            'error': 'Could not analyse the product. Try again with a clearer photo.',
            'analysis': {
                'product_identified': product_name,
                'verdict': 'RETRY',
                'verdict_reason': 'Analysis failed. Please try with better lighting.',
                'affordability_score': 5,
                'alternatives': [],
                'smart_tip': 'Compare prices on at least 3 platforms before buying.',
            }
        }), 200
