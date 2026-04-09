from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import chat_sessions_collection
from models.user_model import get_user_by_uid
from engines.gemini_service import get_artha_response
from datetime import datetime

chat_bp = Blueprint('chat', __name__)

@chat_bp.route('/chat/message', methods=['POST'])
def chat_message():
    auth_header = request.headers.get('Authorization')
    decoded = verify_token(auth_header)
    if not decoded:
        return jsonify({'error': 'Unauthorized'}), 401

    uid = decoded.get('uid')
    data = request.json or {}
    message = data.get('message', '')
    history = data.get('conversation_history', [])
    language = data.get('language', 'en')

    # ── Fetch real user profile from MongoDB for personalized Artha ──────────
    user = get_user_by_uid(uid)
    profile = user.get('profile', {}) if user else {}
    user_name = user.get('name', 'there') if user else 'there'

    # Build rich context using CORRECT field names (matching onboarding.py)
    user_context = {
        'name': user_name,
        'age': profile.get('age'),
        'monthly_salary': profile.get('monthly_salary'),
        'monthly_expense': profile.get('monthly_expense'),
        'current_savings': profile.get('current_savings'),
        'total_emi': profile.get('total_emi', 0),
        'has_health_insurance': profile.get('has_health_insurance', False),
        'has_term_insurance': profile.get('has_term_insurance', False),
        'section_80c': profile.get('section_80c', 0),
        'premium_80d': profile.get('premium_80d', 0),
        'nps_contribution': profile.get('nps_contribution', 0),
        'goal_name': profile.get('financial_goal', profile.get('goal_name', '')),
        'goal_amount': profile.get('financial_goal_amount', profile.get('goal_amount')),
        'goal_years': profile.get('target_timeline', profile.get('goal_years')),
        'risk_appetite': profile.get('risk_appetite', 'moderate'),
    }

    # Also merge any context sent from Flutter (has more recent local data)
    flutter_context = data.get('user_context', {})
    if flutter_context:
        for key, val in flutter_context.items():
            if val is not None and val != '' and val != 0:
                user_context[key] = val

    # ═══════════════════════════════════════════════════════════
    # ARTHA DEBUG LOGGING — Phase 1 diagnostics
    # ═══════════════════════════════════════════════════════════
    user_found = user is not None
    user_profile = user_context  # merged context

    print("=" * 50)
    print(f"[ARTHA] Request received")
    print(f"[ARTHA] User message: {message[:80]}")
    print(f"[ARTHA] UID in request: {uid}")
    print(f"[ARTHA] User found in DB: {user_found}")
    _ms = user_profile.get('monthly_salary') or user_profile.get('monthly_income') or user_profile.get('monthlyIncome') or 0
    print(f"[ARTHA] Monthly income in profile: {_ms}")
    _me = user_profile.get('monthly_expense') or user_profile.get('monthlyExpenses') or 0
    try:
        _surplus = float(_ms) - float(_me)
    except (TypeError, ValueError):
        _surplus = 'CALC_ERROR'
    print(f"[ARTHA] Monthly surplus: {_surplus}")
    print(f"[ARTHA] Profile keys present: "
          f"{list(user_profile.keys())}")
    print("=" * 50)

    try:
        reply = get_artha_response(message, history, user_context, language)

        # Persist chat session in MongoDB
        if chat_sessions_collection is not None:
            chat_sessions_collection.update_one(
                {'firebase_uid': uid},
                {
                    '$push': {
                        'messages': {'$each': [
                            {'role': 'user', 'content': message, 'timestamp': datetime.utcnow()},
                            {'role': 'assistant', 'content': reply, 'timestamp': datetime.utcnow()}
                        ]}
                    },
                    '$set': {
                        'last_message_at': datetime.utcnow(),
                        'firebase_uid': uid,
                    }
                },
                upsert=True
            )

        return jsonify({
            'content': reply,
            'timestamp': datetime.utcnow().isoformat()
        }), 200

    except Exception as e:
        print(f"Chat Error for uid={uid}: {e}")
        return jsonify({'error': 'Artha is busy right now. Please try again.'}), 500
