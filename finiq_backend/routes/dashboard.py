from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.user_model import get_user_profile, get_user_by_uid
from models.database import health_scores_collection, fire_plans_collection, tax_reports_collection, users_collection
from datetime import datetime
import json

dashboard_bp = Blueprint('dashboard', __name__)

def _uid_from_request():
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None, (jsonify({'error': 'No authorization token'}), 401)
    decoded = verify_token(auth_header)
    if not decoded:
        return None, (jsonify({'error': 'Invalid token'}), 401)
    return decoded.get('uid'), None


def _fmt(a):
    """Format a number in Indian notation (₹1.2L, ₹1.5Cr)."""
    try:
        a = abs(float(a or 0))
        if a >= 10_000_000: return f'₹{a/10_000_000:.1f}Cr'
        if a >= 100_000: return f'₹{a/100_000:.1f}L'
        if a >= 1_000: return f'₹{a/1_000:.0f}K'
        return f'₹{int(a)}'
    except (TypeError, ValueError):
        return '₹0'


def generate_gemini_dashboard_brief(user, profile, score, fire, tax):
    """Call Gemini ONCE to generate the complete personalised dashboard JSON.
    Result is saved to MongoDB — never regenerated unless user updates profile.
    """
    name = (user.get('name', 'User') if user else 'User').split(' ')[0]
    monthly_income = float(profile.get('monthly_salary', 0))
    monthly_expense = float(profile.get('monthly_expense', 0))
    monthly_savings = max(0, monthly_income - monthly_expense)
    total_score = score.get('total_score', 0) if score else 0
    grade = score.get('grade', 'D') if score else 'D'
    goal_name = profile.get('financial_goal', 'your goal')
    goal_amount = float(profile.get('financial_goal_amount', 0))
    goal_years = profile.get('target_timeline', 7)
    required_sip = fire.get('required_monthly_sip', 0) if fire else 0
    tax_saving = tax.get('total_potential_saving', 0) if tax else 0
    annual_income = float(profile.get('annual_income', 0))
    has_health = profile.get('has_health_insurance', False)
    has_term = profile.get('has_term_insurance', False)
    current_savings = float(profile.get('current_savings', 0))
    total_emi = float(profile.get('total_emi', 0))

    prompt = f"""You are Artha, India's smartest AI financial mentor.
Analyse this user's complete financial profile and generate
a personalised dashboard JSON. Return ONLY valid JSON.
No markdown. No backticks. No explanation. Just JSON.

USER PROFILE:
Name: {name} | Age: {profile.get('age')}
Monthly Income: {_fmt(monthly_income)}
Monthly Expenses: {_fmt(monthly_expense)}
Monthly Savings: {_fmt(monthly_savings)}
Annual Income: {_fmt(annual_income)}
Health Insurance: {'YES' if has_health else 'NO — CRITICAL'}
Term Insurance: {'YES' if has_term else 'NO — CRITICAL'}
Current Savings: {_fmt(current_savings)}
Total EMI: {_fmt(total_emi)}
80C Invested: {_fmt(profile.get('section_80c', 0))}
NPS Contribution: {_fmt(profile.get('nps_contribution', 0))}
Goal: {goal_name} — {_fmt(goal_amount)} in {goal_years} years
Risk Appetite: {profile.get('risk_appetite')}

CALCULATED RESULTS:
Health Score: {total_score}/100 (Grade {grade})
Required Monthly SIP: {_fmt(required_sip)}
Tax Saving Available: {_fmt(tax_saving)}

Generate this exact JSON:
{{
  "artha_morning_brief": "2-3 sentences. Use {name}'s name. Reference their exact numbers. Be specific, warm, and end with one actionable insight.",
  "health_insight": "1-2 sentences explaining {total_score}/100 score specifically.",
  "fire_insight": "1-2 sentences about {goal_name} goal. Is {_fmt(required_sip)}/mo realistic?",
  "tax_insight": "1 sentence about their tax situation and the {_fmt(tax_saving)} saving opportunity.",
  "priority_action_1": {{
    "title": "Most urgent action for {name}",
    "subtitle": "Specific detail with their numbers",
    "urgency": "CRITICAL",
    "route": "/health"
  }},
  "priority_action_2": {{
    "title": "Second priority",
    "subtitle": "Specific detail",
    "urgency": "HIGH",
    "route": "/tax"
  }},
  "priority_action_3": {{
    "title": "Third priority",
    "subtitle": "Specific detail",
    "urgency": "HIGH",
    "route": "/fire"
  }},
  "artha_greeting": "Opening message when {name} opens Artha chat. Reference their profile specifically.",
  "weekly_tip": "One specific financial tip based on their situation this week."
}}"""

    try:
        from engines.gemini_service import _call_gemini
        response_text = _call_gemini(prompt, prompt)

        # Strip any accidental markdown
        cleaned = response_text.strip()
        if cleaned.startswith('```'):
            cleaned = cleaned.split('```')[1]
            if cleaned.startswith('json'):
                cleaned = cleaned[4:]

        return json.loads(cleaned.strip())

    except Exception as e:
        print(f'Gemini dashboard generation failed: {e}')
        return _fallback_brief(name, total_score, grade, goal_name, tax_saving,
                               has_health, has_term, monthly_income, current_savings,
                               monthly_expense)


def _fallback_brief(name, score, grade, goal, tax_saving,
                    has_health=True, has_term=True,
                    monthly_income=0, current_savings=0,
                    monthly_expense=1):
    """Never show empty dashboard — always return structured fallback."""

    # Insurance gap is the most critical
    if not has_health and not has_term:
        brief = (f'{name}, your score of {score} ({grade}) shows critical gaps. '
                 f'Zero insurance coverage is your biggest risk — a ₹1Cr term plan '
                 f'costs just ₹800/mo. Fix this first to boost your score by 20 points.')
    elif monthly_income > 0 and current_savings < monthly_expense * 3:
        months = round(current_savings / max(monthly_expense, 1), 1)
        brief = (f'{name}, your emergency fund covers only {months} months. '
                 f'Build it to 6 months before investing aggressively.')
    elif score >= 80:
        brief = (f'{name}, your score of {score} ({grade}) shows a solid foundation. '
                 f'Focus on increasing your SIP and diversifying into international index funds.')
    else:
        brief = (f'{name}, your financial score is {score}/100 ({grade}). '
                 f'Let\'s work on improving your weakest dimensions today.')

    return {
        'artha_morning_brief': brief,
        'health_insight': f'Score of {score} means there are areas to improve.',
        'fire_insight': f'Your {goal} goal is being tracked.',
        'tax_insight': 'Review your deductions for tax savings.',
        'priority_action_1': {
            'title': 'Review your insurance coverage',
            'subtitle': 'Critical protection gap detected',
            'urgency': 'CRITICAL', 'route': '/health'
        },
        'priority_action_2': {
            'title': 'Explore tax deductions',
            'subtitle': f'{_fmt(tax_saving)} saving available',
            'urgency': 'HIGH', 'route': '/tax'
        },
        'priority_action_3': {
            'title': 'Check your FIRE plan',
            'subtitle': 'Review monthly SIP target',
            'urgency': 'HIGH', 'route': '/fire'
        },
        'artha_greeting': (f'Hi {name}! I know your complete financial '
                           f'profile. What would you like to work on today?'),
        'weekly_tip': 'Try to save at least 20% of your income this month.'
    }


@dashboard_bp.route('/user/dashboard', methods=['GET'])
def get_dashboard():
    uid, err = _uid_from_request()
    if err:
        return err

    user = get_user_by_uid(uid)
    profile = user.get('profile', {}) if user else {}
    onboarding_complete = user.get('onboarding_complete', False) if user else False

    if not onboarding_complete:
        return jsonify({
            'has_profile': False,
            'user': {
                'name': user.get('name', 'User') if user else 'User',
                'photo_url': user.get('photo_url', '') if user else '',
            }
        }), 200

    score = health_scores_collection.find_one(
        {'firebase_uid': uid}, {'_id': 0},
    ) if health_scores_collection else None
    fire  = fire_plans_collection.find_one(
        {'firebase_uid': uid}, {'_id': 0},
    ) if fire_plans_collection else None
    tax   = tax_reports_collection.find_one(
        {'firebase_uid': uid}, {'_id': 0},
    ) if tax_reports_collection else None

    # ── Gemini Dashboard Brief (cached in MongoDB) ─────────────────────────
    gemini_dashboard = user.get('gemini_dashboard') if user else None
    force_refresh = request.args.get('refresh') == 'true'

    if gemini_dashboard is None or force_refresh:
        # Generate via Gemini and cache it
        gemini_dashboard = generate_gemini_dashboard_brief(user, profile, score, fire, tax)
        try:
            if users_collection:
                users_collection.update_one(
                    {'firebase_uid': uid},
                    {'$set': {
                        'gemini_dashboard': gemini_dashboard,
                        'dashboard_generated_at': datetime.utcnow()
                    }}
                )
        except Exception as e:
            print(f'Failed to cache Gemini dashboard: {e}')

    artha_brief = gemini_dashboard.get('artha_morning_brief', '') if isinstance(gemini_dashboard, dict) else str(gemini_dashboard)

    return jsonify({
        'has_profile': True,
        'user': {
            'name': user.get('name', 'User') if user else 'User',
            'photo_url': user.get('photo_url', '') if user else '',
        },
        'profile': profile,
        'health_score': score,
        'fire_plan': fire,
        'tax_report': tax,
        'artha_brief': artha_brief,
        'gemini_dashboard': gemini_dashboard,
        'priority_actions': score.get('priority_actions', []) if score else [],
    }), 200


@dashboard_bp.route('/user/profile', methods=['PUT'])
def update_profile():
    """Allow user to update personal info from Profile screen."""
    uid, err = _uid_from_request()
    if err:
        return err

    from models.user_model import update_user_fields
    data = request.json or {}
    allowed = {'name', 'profile'}
    filtered = {k: v for k, v in data.items() if k in allowed}
    if filtered:
        update_user_fields(uid, filtered)
        # Invalidate cached Gemini dashboard so it regenerates on next load
        try:
            if users_collection:
                users_collection.update_one(
                    {'firebase_uid': uid},
                    {'$unset': {'gemini_dashboard': ''}}
                )
        except Exception:
            pass
    return jsonify({'success': True}), 200
