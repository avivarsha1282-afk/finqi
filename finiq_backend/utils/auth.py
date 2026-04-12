"""
R12: Shared auth utilities for Flask routes.
Single source of truth for Firebase token verification.
"""

from functools import wraps
from flask import request, jsonify
from models.firebase import verify_token


def get_uid_from_request():
    """
    Extract and verify Firebase UID from Authorization header.
    Returns UID string or None if invalid/missing.
    """
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None
    decoded = verify_token(auth_header)
    if not decoded:
        return None
    return decoded.get('uid')


def require_auth(f):
    """
    Decorator: protects routes that require authentication.

    Usage:
        @app.route('/api/protected')
        @require_auth
        def protected_endpoint(uid):
            # uid is the verified Firebase UID
            ...

    The verified UID is injected as the first argument to the route function.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        uid = get_uid_from_request()
        if not uid:
            return jsonify({
                'error': 'Unauthorized. Valid Firebase token required.'
            }), 401
        return f(uid, *args, **kwargs)
    return decorated
