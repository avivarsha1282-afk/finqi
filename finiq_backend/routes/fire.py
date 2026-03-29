from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import fire_plans_collection

fire_bp = Blueprint('fire', __name__)

@fire_bp.route('/fire/plan', methods=['POST'])
def get_fire_plan():
    auth_header = request.headers.get('Authorization')
    decoded = verify_token(auth_header)
    uid = decoded.get('uid') if decoded else 'demo_user'
    
    doc = fire_plans_collection.find_one({'firebase_uid': uid}, {'_id': 0})
    if doc:
        return jsonify(doc), 200
        
    return jsonify({'error': 'FIRE plan not found. Complete onboarding first.'}), 404
