"""
Artha Conversation Management — ChatGPT-style history
Endpoints:
  POST   /artha/conversations          — create new conversation
  GET    /artha/conversations           — list conversations for a user
  GET    /artha/conversations/<id>/messages — get messages
  POST   /artha/conversations/<id>/messages — send message + get Artha response
  DELETE /artha/conversations/<id>      — delete conversation
"""

import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import artha_conversations_collection
from models.user_model import get_user_by_uid
from engines.gemini_service import get_artha_response

artha_bp = Blueprint('artha', __name__)


def _auth(req):
    """Verify Firebase token and return uid or None."""
    auth_header = req.headers.get('Authorization')
    decoded = verify_token(auth_header)
    if not decoded:
        return None
    return decoded.get('uid')


# ═══════════════════════════════════════════════════════════
# POST /artha/conversations — Create new conversation
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations', methods=['POST'])
def create_conversation():
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'error': 'Database unavailable'}), 503

    doc = {
        'conversationId': str(uuid.uuid4()),
        'userId': uid,
        'title': 'New Chat',
        'messages': [],
        'createdAt': datetime.utcnow(),
        'updatedAt': datetime.utcnow(),
    }
    artha_conversations_collection.insert_one(doc)

    return jsonify({
        'conversationId': doc['conversationId'],
        'title': doc['title'],
        'createdAt': doc['createdAt'].isoformat(),
    }), 201


# ═══════════════════════════════════════════════════════════
# GET /artha/conversations — List conversations for user
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations', methods=['GET'])
def list_conversations():
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'conversations': []}), 200

    limit = int(request.args.get('limit', 20))
    cursor = artha_conversations_collection.find(
        {'userId': uid},
        {'_id': 0, 'conversationId': 1, 'title': 1,
         'createdAt': 1, 'updatedAt': 1, 'messages': {'$slice': -1}}
    ).sort('updatedAt', -1).limit(limit)

    results = []
    for doc in cursor:
        last_msg = ''
        msg_count = 0
        if doc.get('messages'):
            last_msg = doc['messages'][-1].get('content', '')[:80]
        # Get total message count with a separate query
        full_doc = artha_conversations_collection.find_one(
            {'conversationId': doc['conversationId']},
            {'messages': 1}
        )
        if full_doc and full_doc.get('messages'):
            msg_count = len(full_doc['messages'])

        results.append({
            'id': doc['conversationId'],
            'title': doc.get('title', 'New Chat'),
            'createdAt': doc.get('createdAt', datetime.utcnow()).isoformat(),
            'messageCount': msg_count,
            'lastMessage': last_msg,
        })

    return jsonify({'conversations': results}), 200


# ═══════════════════════════════════════════════════════════
# GET /artha/conversations/<id>/messages — Get all messages
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations/<conv_id>/messages', methods=['GET'])
def get_messages(conv_id):
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'messages': []}), 200

    doc = artha_conversations_collection.find_one(
        {'conversationId': conv_id, 'userId': uid},
        {'_id': 0, 'messages': 1}
    )

    if not doc:
        return jsonify({'error': 'Conversation not found'}), 404

    messages = []
    for m in doc.get('messages', []):
        messages.append({
            'id': m.get('id', ''),
            'role': m.get('role', 'user'),
            'content': m.get('content', ''),
            'timestamp': m.get('timestamp', datetime.utcnow()).isoformat()
                         if isinstance(m.get('timestamp'), datetime)
                         else str(m.get('timestamp', '')),
        })

    return jsonify({'messages': messages}), 200


# ═══════════════════════════════════════════════════════════
# POST /artha/conversations/<id>/messages — Send + get reply
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations/<conv_id>/messages', methods=['POST'])
def send_message(conv_id):
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'error': 'Database unavailable'}), 503

    data = request.json or {}
    user_message = data.get('message', '').strip()
    user_profile = data.get('userProfile', {})
    language = data.get('language', 'en')

    if not user_message:
        return jsonify({'error': 'Empty message'}), 400

    # Find the conversation
    conv = artha_conversations_collection.find_one(
        {'conversationId': conv_id, 'userId': uid}
    )
    if not conv:
        return jsonify({'error': 'Conversation not found'}), 404

    # Build conversation history from existing messages
    history = [
        {'role': m.get('role'), 'content': m.get('content', '')}
        for m in conv.get('messages', [])[-10:]
    ]

    # Build user context from profile data (merge DB + request)
    db_user = get_user_by_uid(uid)
    db_profile = db_user.get('profile', {}) if db_user else {}
    # Name priority: MongoDB profile fullName > top-level name > 'there'
    user_name = (
        db_profile.get('fullName') or
        db_profile.get('full_name') or
        db_profile.get('name') or
        (db_user.get('name') if db_user else None) or
        'there'
    )
    if user_name:
        user_name = user_name.strip().split(' ')[0]

    user_context = {
        'name': user_name,
        'age': db_profile.get('age'),
        'monthly_salary': db_profile.get('monthly_salary'),
        'monthly_expense': db_profile.get('monthly_expense'),
        'current_savings': db_profile.get('current_savings'),
        'total_emi': db_profile.get('total_emi', 0),
        'has_health_insurance': db_profile.get('has_health_insurance', False),
        'has_term_insurance': db_profile.get('has_term_insurance', False),
        'section_80c': db_profile.get('section_80c', 0),
        'premium_80d': db_profile.get('premium_80d', 0),
        'nps_contribution': db_profile.get('nps_contribution', 0),
        'goal_name': db_profile.get('financial_goal', ''),
        'goal_amount': db_profile.get('financial_goal_amount'),
        'goal_years': db_profile.get('target_timeline'),
        'risk_appetite': db_profile.get('risk_appetite', 'moderate'),
    }

    # Merge Flutter-side profile (has camelCase + newer local data)
    for key, val in user_profile.items():
        if val is not None and val != '' and val != 0:
            user_context[key] = val

    # Get Artha response
    try:
        reply = get_artha_response(user_message, history, user_context, language)
    except Exception as e:
        print(f'[ARTHA] Error: {e}')
        reply = "I'm having trouble right now. Please try again in a moment."

    # Build message docs
    now = datetime.utcnow()
    user_msg_doc = {
        'id': str(uuid.uuid4()),
        'role': 'user',
        'content': user_message,
        'timestamp': now,
    }
    artha_msg_doc = {
        'id': str(uuid.uuid4()),
        'role': 'model',
        'content': reply,
        'timestamp': now,
    }

    # Auto-title: first user message → first 40 chars
    update_ops = {
        '$push': {'messages': {'$each': [user_msg_doc, artha_msg_doc]}},
        '$set': {'updatedAt': now},
    }
    if not conv.get('messages'):
        title = user_message[:40].strip()
        if len(user_message) > 40:
            title += '...'
        update_ops['$set']['title'] = title

    artha_conversations_collection.update_one(
        {'conversationId': conv_id},
        update_ops
    )

    return jsonify({
        'response': reply,
        'timestamp': now.isoformat(),
    }), 200


# ═══════════════════════════════════════════════════════════
# DELETE /artha/conversations/<id> — Delete conversation
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations/<conv_id>', methods=['DELETE'])
def delete_conversation(conv_id):
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'error': 'Database unavailable'}), 503

    result = artha_conversations_collection.delete_one(
        {'conversationId': conv_id, 'userId': uid}
    )

    if result.deleted_count == 0:
        return jsonify({'error': 'Conversation not found'}), 404

    return jsonify({'success': True}), 200
