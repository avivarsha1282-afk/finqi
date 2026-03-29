from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import tax_reports_collection

tax_bp = Blueprint('tax', __name__)

@tax_bp.route('/tax/compare', methods=['POST'])
def get_tax_report():
    auth_header = request.headers.get('Authorization')
    decoded = verify_token(auth_header)
    uid = decoded.get('uid') if decoded else 'demo_user'
    
    doc = tax_reports_collection.find_one({'firebase_uid': uid}, {'_id': 0})
    if doc:
        return jsonify(doc), 200
        
    return jsonify({'error': 'Tax report not found. Complete onboarding first.'}), 404
