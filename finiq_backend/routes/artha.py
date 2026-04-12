"""
Artha Conversation Management — ChatGPT-style history
Production v2 — Security hardened.

Fixes applied:
  R1: Messages capped at 50 per conversation ($slice -50)
  R5: list_conversations uses aggregation (no N+1)
  R6: Per-user rate limiting (10/min, 100/day)
  R7: Message length capped at 2000 chars

Endpoints:
  POST   /artha/conversations               — create new conversation
  GET    /artha/conversations               — list conversations for a user
  GET    /artha/conversations/<id>/messages  — get messages
  POST   /artha/conversations/<id>/messages  — send message + get Artha response
  DELETE /artha/conversations/<id>           — delete conversation
"""

import uuid
import time
from datetime import datetime
from collections import defaultdict
from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import artha_conversations_collection
from models.user_model import get_user_by_uid
from engines.gemini_service import get_artha_response

artha_bp = Blueprint('artha', __name__)

# ═══════════════════════════════════════════════════════════
# Constants
# ═══════════════════════════════════════════════════════════
MAX_MESSAGES_PER_CONVERSATION = 50   # R1: Hard cap per conversation
MAX_MESSAGE_LENGTH = 2000            # R7: Characters per message
RATE_LIMIT_WINDOW_SECONDS = 60       # R6: 1-minute window
RATE_LIMIT_MAX_PER_MINUTE = 10       # R6: 10 messages per minute
RATE_LIMIT_MAX_PER_DAY = 100         # R6: 100 messages per day


# ═══════════════════════════════════════════════════════════
# R6: Per-user rate limiting (in-memory)
# ═══════════════════════════════════════════════════════════
_artha_request_log: dict = defaultdict(list)


def _check_rate_limit(uid: str):
    """Check per-user rate limit. Returns (allowed: bool, error_msg: str)."""
    now = time.time()
    user_log = _artha_request_log[uid]

    # Clean entries older than 24 hours
    cutoff_24h = now - 86400
    _artha_request_log[uid] = [t for t in user_log if t > cutoff_24h]
    user_log = _artha_request_log[uid]

    # Daily limit
    if len(user_log) >= RATE_LIMIT_MAX_PER_DAY:
        return False, (f'You\'ve reached your daily limit of '
                       f'{RATE_LIMIT_MAX_PER_DAY} messages. Resets in 24 hours.')

    # Per-minute limit
    cutoff_1min = now - RATE_LIMIT_WINDOW_SECONDS
    recent = [t for t in user_log if t > cutoff_1min]
    if len(recent) >= RATE_LIMIT_MAX_PER_MINUTE:
        return False, 'Please wait a moment before sending another message.'

    # Allowed — record this request
    _artha_request_log[uid].append(now)
    return True, ''


# ═══════════════════════════════════════════════════════════
# Auth helper
# ═══════════════════════════════════════════════════════════
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
        'messageCount': 0,                        # R1: Track count separately
        'maxMessages': MAX_MESSAGES_PER_CONVERSATION,  # R1: Self-documenting limit
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
# R5: Single aggregation query (replaces N+1 pattern)
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations', methods=['GET'])
def list_conversations():
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'conversations': []}), 200

    limit = min(int(request.args.get('limit', 20)), 50)

    # R5: Single aggregation — replaces N+1 find_one loop
    pipeline = [
        {'$match': {'userId': uid}},
        {'$sort': {'updatedAt': -1}},
        {'$limit': limit},
        {'$addFields': {
            'messageCount': {'$size': {'$ifNull': ['$messages', []]}},
            'lastMessage': {'$arrayElemAt': ['$messages', -1]},
        }},
        {'$project': {
            '_id': 0,
            'conversationId': 1,
            'title': 1,
            'createdAt': 1,
            'messageCount': 1,
            'lastMessage.content': 1,
        }},
    ]

    results = []
    for doc in artha_conversations_collection.aggregate(pipeline):
        last_content = ''
        last_msg = doc.get('lastMessage')
        if last_msg and isinstance(last_msg, dict):
            last_content = last_msg.get('content', '')[:80]

        results.append({
            'id': doc.get('conversationId', ''),
            'title': doc.get('title', 'New Chat'),
            'createdAt': doc.get('createdAt', datetime.utcnow()).isoformat()
                         if isinstance(doc.get('createdAt'), datetime)
                         else str(doc.get('createdAt', '')),
            'messageCount': doc.get('messageCount', 0),
            'lastMessage': last_content,
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
# R1: $slice -50 on $push
# R6: Per-user rate check
# R7: Message length validation
# ═══════════════════════════════════════════════════════════

@artha_bp.route('/artha/conversations/<conv_id>/messages', methods=['POST'])
def send_message(conv_id):
    uid = _auth(request)
    if not uid:
        return jsonify({'error': 'Unauthorized'}), 401

    if artha_conversations_collection is None:
        return jsonify({'error': 'Database unavailable'}), 503

    # ── R6: Per-user rate limit check ────────────────────────
    allowed, rate_err = _check_rate_limit(uid)
    if not allowed:
        return jsonify({'error': rate_err, 'rateLimited': True}), 429

    data = request.json or {}
    user_message = data.get('message', '').strip()
    user_profile = data.get('userProfile', {})
    language = data.get('language', 'en')

    # ── R7: Message validation ───────────────────────────────
    if not user_message:
        return jsonify({'error': 'Empty message'}), 400

    if len(user_message) > MAX_MESSAGE_LENGTH:
        return jsonify({
            'error': f'Message too long. Maximum {MAX_MESSAGE_LENGTH} characters. '
                     f'Your message has {len(user_message)}.'
        }), 400

    # Enforce the cap (defense-in-depth)
    user_message = user_message[:MAX_MESSAGE_LENGTH]

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

    # ── R1: $push with $slice — keeps last 50 messages only ──
    update_ops = {
        '$push': {
            'messages': {
                '$each': [user_msg_doc, artha_msg_doc],
                '$slice': -MAX_MESSAGES_PER_CONVERSATION,  # Keep LAST 50 only
            }
        },
        '$set': {'updatedAt': now},
        '$inc': {'messageCount': 2},
    }

    # Auto-title: first user message → first 40 chars
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
