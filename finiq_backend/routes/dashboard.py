from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.user_model import get_user_profile, get_user_by_uid
from models.database import health_scores_collection, fire_plans_collection, tax_reports_collection

dashboard_bp = Blueprint('dashboard', __name__)

def _uid_from_request():
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None, (jsonify({'error': 'No authorization token'}), 401)
    decoded = verify_token(auth_header)
    if not decoded:
        return None, (jsonify({'error': 'Invalid token'}), 401)
    return decoded.get('uid'), None

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
    )
    fire  = fire_plans_collection.find_one(
        {'firebase_uid': uid}, {'_id': 0},
    )
    tax   = tax_reports_collection.find_one(
        {'firebase_uid': uid}, {'_id': 0},
    )

    return jsonify({
        'has_profile': True,
        'user': {
            'name': user.get('name', 'User') if user else 'User',
            'photo_url': user.get('photo_url', '') if user else '',
        },
        'latest_score': score,
        'fire_plan': fire,
        'tax_report': tax,
        'artha_brief': (
            'Starting ₹5,000/mo in a Nifty 50 index fund costs less than '
            'most weekend dinners — and grows to ₹82,000 in 10 years.'
        ),
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
    return jsonify({'success': True}), 200
