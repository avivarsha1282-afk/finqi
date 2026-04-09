from pymongo import MongoClient, ASCENDING
import os
import logging
from dotenv import load_dotenv

load_dotenv()

db_available = False
try:
    client = MongoClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017/'), serverSelectionTimeoutMS=5000)
    client.server_info() # trigger connection
    db_available = True
    logging.info("MongoDB connection successful")
except Exception as e:
    logging.error(f"MongoDB connection failed: {e}")
    client = None

if db_available:
    db = client['finiq']
    users_collection = db['users']
    health_scores_collection = db['health_scores']
    fire_plans_collection = db['fire_plans']
    tax_reports_collection = db['tax_reports']
    chat_sessions_collection = db['chat_sessions']
    artha_conversations_collection = db['artha_conversations']
else:
    db = None
    users_collection = None
    health_scores_collection = None
    fire_plans_collection = None
    tax_reports_collection = None
    chat_sessions_collection = None
    artha_conversations_collection = None


def create_indexes():
    """Create indexes on firebase_uid for all collections.
    Called once at server startup. Idempotent — safe to call multiple times."""
    if not db_available:
        return
    
    users_collection.create_index([('firebase_uid', ASCENDING)], unique=True, background=True)
    health_scores_collection.create_index([('firebase_uid', ASCENDING)], unique=True, background=True)
    fire_plans_collection.create_index([('firebase_uid', ASCENDING)], unique=True, background=True)
    tax_reports_collection.create_index([('firebase_uid', ASCENDING)], unique=True, background=True)
    chat_sessions_collection.create_index([('firebase_uid', ASCENDING)], unique=True, background=True)
    artha_conversations_collection.create_index([('userId', ASCENDING), ('createdAt', ASCENDING)], background=True)
