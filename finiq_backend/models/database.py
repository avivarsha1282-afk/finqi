from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()

client = MongoClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017/'))
db = client['finiq']

users_collection = db['users']
health_scores_collection = db['health_scores']
fire_plans_collection = db['fire_plans']
tax_reports_collection = db['tax_reports']
chat_sessions_collection = db['chat_sessions']
