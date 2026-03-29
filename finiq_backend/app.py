from flask import Flask
from flask_cors import CORS
from routes.auth import auth_bp
from routes.onboarding import onboarding_bp
from routes.score import score_bp
from routes.fire import fire_bp
from routes.tax import tax_bp
from routes.chat import chat_bp
from routes.dashboard import dashboard_bp
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app, origins="*")

app.register_blueprint(auth_bp, url_prefix='/api')
app.register_blueprint(onboarding_bp, url_prefix='/api')
app.register_blueprint(score_bp, url_prefix='/api')
app.register_blueprint(fire_bp, url_prefix='/api')
app.register_blueprint(tax_bp, url_prefix='/api')
app.register_blueprint(chat_bp, url_prefix='/api')
app.register_blueprint(dashboard_bp, url_prefix='/api')

@app.route('/ping')
def ping():
    return {'status': 'alive', 'service': 'FinIQ API v4.0'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
