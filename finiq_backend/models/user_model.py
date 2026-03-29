from models.database import users_collection
from datetime import datetime

def get_user_by_uid(uid):
    return users_collection.find_one({'firebase_uid': uid}, {'_id': 0})

def create_user(uid, email, name, photo_url=''):
    user = {
        'firebase_uid': uid,
        'email': email,
        'name': name,
        'photo_url': photo_url,
        'profile': {},
        'onboarding_complete': False,
        'language': 'en',
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow(),
    }
    users_collection.insert_one(user)
    return user

def update_user_profile(uid, profile_data):
    users_collection.update_one(
        {'firebase_uid': uid},
        {'$set': {
            'profile': profile_data,
            'onboarding_complete': True,
            'updated_at': datetime.utcnow(),
        }}
    )

def update_user_fields(uid, fields: dict):
    """Update arbitrary top-level user fields."""
    fields['updated_at'] = datetime.utcnow()
    users_collection.update_one(
        {'firebase_uid': uid},
        {'$set': fields}
    )

def get_user_profile(uid):
    user = get_user_by_uid(uid)
    return user.get('profile', {}) if user else {}
