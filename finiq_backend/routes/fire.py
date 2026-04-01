from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import fire_plans_collection
from engines.fire_engine import calculate_fire_plan

fire_bp = Blueprint('fire', __name__)

@fire_bp.route('/fire/plan', methods=['POST'])
def get_fire_plan():
    auth_header = request.headers.get('Authorization')
    decoded = verify_token(auth_header)
    uid = decoded.get('uid') if decoded else 'demo_user'

    data = request.json or {}
    target_amount = data.get('target_amount')
    target_years = data.get('target_years')
    current_savings = data.get('current_savings')

    # If user sent custom inputs (from FIRE screen sliders), recalculate live
    if target_amount is not None and target_years is not None and current_savings is not None:
        plan = calculate_fire_plan(
            float(target_amount),
            int(target_years),
            float(current_savings),
        )
        return jsonify(plan), 200

    # Otherwise return the pre-computed plan from onboarding
    doc = fire_plans_collection.find_one({'firebase_uid': uid}, {'_id': 0})
    if doc:
        # Remove MongoDB internal fields
        doc.pop('firebase_uid', None)
        doc.pop('created_at', None)
        return jsonify(doc), 200

    return jsonify({'error': 'FIRE plan not found. Complete onboarding first.'}), 404
