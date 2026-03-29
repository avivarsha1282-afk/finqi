from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import health_scores_collection

score_bp = Blueprint('score', __name__)

@score_bp.route('/score/calculate', methods=['POST'])
def get_score():
    auth_header = request.headers.get('Authorization')
    decoded = verify_token(auth_header)
    uid = decoded.get('uid') if decoded else 'demo_user'
    
    doc = health_scores_collection.find_one({'firebase_uid': uid}, {'_id': 0})
    if doc:
        return jsonify(doc), 200
        
    return jsonify({'error': 'Score not found. Complete onboarding first.'}), 404
