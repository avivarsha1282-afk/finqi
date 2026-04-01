from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.user_model import update_user_profile, get_user_profile
from engines.health_score_engine import calculate_health_score
from engines.fire_engine import calculate_fire_plan
from engines.tax_engine import compare_regimes
from models.database import health_scores_collection, fire_plans_collection, tax_reports_collection
from datetime import datetime

onboarding_bp = Blueprint('onboarding', __name__)

def _validate_onboarding_data(data: dict):
    """Validate onboarding input — reject negative numbers and unrealistic values."""
    numeric_fields = [
        'monthly_salary', 'monthly_expense', 'current_savings',
        'financial_goal_amount', 'total_emi', 'section_80c',
        'premium_80d', 'nps_contribution', 'monthly_rent',
    ]
    for field in numeric_fields:
        value = data.get(field)
        if value is None:
            continue
        try:
            # Strip commas and currency symbols before parsing
            if isinstance(value, str):
                value = value.replace(',', '').replace('₹', '').strip()
            val = float(value)
            if val < 0:
                return False, f'{field} cannot be negative'
            if field == 'monthly_salary' and val > 10_000_000:
                return False, f'{field} value seems unrealistic (max ₹1Cr/month)'
        except (TypeError, ValueError):
            return False, f'{field} must be a number'
    return True, 'valid'

def _uid_from_request():
    """Extract verified UID from Authorization header. Returns (uid, error_response)."""
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None, (jsonify({'error': 'No authorization token'}), 401)
    decoded = verify_token(auth_header)
    if not decoded:
        return None, (jsonify({'error': 'Invalid token'}), 401)
    return decoded.get('uid'), None

@onboarding_bp.route('/onboarding/save', methods=['POST'])
def save_onboarding():
    uid, err = _uid_from_request()
    if err:
        return err

    data = request.json or {}

    # ── Validate input ───────────────────────────────────────────────────────
    valid, err_msg = _validate_onboarding_data(data)
    if not valid:
        return jsonify({'error': err_msg}), 400

    # ── Build normalized profile ─────────────────────────────────────────────
    def _float(key, default=0.0):
        try: return float(data.get(key, default))
        except: return float(default)

    def _int(key, default=0):
        try: return int(data.get(key, default))
        except: return int(default)

    def _bool(key, default=False):
        v = data.get(key, default)
        if isinstance(v, bool): return v
        return str(v).lower() in ('true', '1', 'yes')

    monthly_salary = _float('monthly_salary')
    annual_income  = monthly_salary * 12

    profile = {
        'age':                  _int('age'),
        'monthly_salary':       monthly_salary,
        'annual_income':        annual_income,
        'monthly_expense':      _float('monthly_expense'),
        'current_savings':      _float('current_savings'),
        'total_emi':            _float('total_emi'),
        'has_health_insurance': _bool('has_health_insurance'),
        'has_term_insurance':   _bool('has_term_insurance'),
        'section_80c':          _float('section_80c'),
        'premium_80d':          _float('premium_80d'),
        'nps_contribution':     _float('nps_contribution'),
        'monthly_rent':         _float('monthly_rent'),
        'financial_goal':       data.get('financial_goal', ''),
        'financial_goal_amount': _float('financial_goal_amount', 10_000_000),
        'target_timeline':      _int('target_timeline', 10),
        'risk_appetite':        data.get('risk_appetite', 'moderate'),
    }

    # ── Save profile & mark onboarding complete ──────────────────────────────
    update_user_profile(uid, profile)

    # ── Health Score ─────────────────────────────────────────────────────────
    score = calculate_health_score(profile)
    health_scores_collection.update_one(
        {'firebase_uid': uid},
        {'$set': {**score, 'firebase_uid': uid, 'calculated_at': datetime.utcnow()}},
        upsert=True
    )

    # ── FIRE Plan ────────────────────────────────────────────────────────────
    fire_plan = calculate_fire_plan(
        profile['financial_goal_amount'],
        profile['target_timeline'],
        profile['current_savings'],
        monthly_income=profile['monthly_salary']
    )
    fire_plans_collection.update_one(
        {'firebase_uid': uid},
        {'$set': {**fire_plan, 'firebase_uid': uid, 'created_at': datetime.utcnow()}},
        upsert=True
    )

    # ── Tax Report ───────────────────────────────────────────────────────────
    tax_report = compare_regimes(
        annual_income,
        investment_80c=profile['section_80c'],
        premium_80d=profile['premium_80d'],
        nps_contribution=profile['nps_contribution'],
    )
    tax_reports_collection.update_one(
        {'firebase_uid': uid},
        {'$set': {**tax_report, 'firebase_uid': uid,
                  'annual_income': annual_income,
                  'created_at': datetime.utcnow()}},
        upsert=True
    )

    return jsonify({
        'success': True,
        'health_score': score,
        'fire_plan': fire_plan,
        'tax_report': tax_report,
    }), 200
