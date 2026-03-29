from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.user_model import get_user_by_uid, create_user

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/auth/verify', methods=['POST'])
def verify_auth():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'No authorization token provided'}), 401

    decoded = verify_token(auth_header)
    if not decoded:
        return jsonify({'error': 'Invalid or expired token'}), 401

    uid = decoded.get('uid')
    email = decoded.get('email', '')
    name = decoded.get('name', email.split('@')[0] if email else 'User')
    photo_url = decoded.get('picture', '')

    user = get_user_by_uid(uid)
    is_new = False

    if not user:
        user = create_user(uid, email, name, photo_url)
        is_new = True

    return jsonify({
        'success': True,
        'user_id': uid,
        'is_new_user': is_new,
        'onboarding_complete': user.get('onboarding_complete', False),
        'name': user.get('name', name),
        'email': user.get('email', email),
        'photo_url': user.get('photo_url', photo_url),
        'profile': user.get('profile', {}),
    }), 200
