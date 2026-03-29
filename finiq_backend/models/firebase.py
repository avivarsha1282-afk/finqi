import firebase_admin
from firebase_admin import credentials, auth
import os
import json
from dotenv import load_dotenv

load_dotenv()

# Initialize Firebase Admin
try:
    if not firebase_admin._apps:
        # Load from string in env var
        pk = os.getenv('FIREBASE_PRIVATE_KEY', '').replace('\\n', '\n')
        creds_dict = {
            "type": "service_account",
            "project_id": os.getenv('FIREBASE_PROJECT_ID'),
            "private_key": pk,
            "client_email": os.getenv('FIREBASE_CLIENT_EMAIL'),
            "token_uri": "https://oauth2.googleapis.com/token"
        }
        cred = credentials.Certificate(creds_dict)
        firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Firebase Init Error: {e}")

def verify_token(token):
    try:
        if not token: return None
        token = token.replace('Bearer ', '')
        decoded = auth.verify_id_token(token)
        return decoded
    except Exception as e:
        print(f"Token Verify Error: {e}")
        return None
