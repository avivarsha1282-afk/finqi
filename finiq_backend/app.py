import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# ── CORS ─────────────────────────────────────────────────────────────────────
# Production: restrict to known origins only. Debug: allow all.
IS_PRODUCTION = os.getenv('RAILWAY_ENVIRONMENT') or os.getenv('FLASK_ENV') == 'production'

if IS_PRODUCTION:
    allowed_origins = [
        'https://finiq-backend-production.up.railway.app',
        # Add your Flutter web domain here if ever needed
    ]
    CORS(app, origins=allowed_origins, supports_credentials=True)
else:
    CORS(app, origins='*')

# ── Rate Limiting ────────────────────────────────────────────────────────────
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=['200 per day', '50 per hour'],
    storage_uri='memory://',
)

# ── Database Setup ───────────────────────────────────────────────────────────
from models.database import create_indexes
try:
    create_indexes()
except Exception as e:
    print(f'Index creation skipped: {e}')

# ── Register Blueprints ─────────────────────────────────────────────────────
from routes.auth import auth_bp
from routes.onboarding import onboarding_bp
from routes.score import score_bp
from routes.fire import fire_bp
from routes.tax import tax_bp
from routes.dashboard import dashboard_bp
from routes.chat import chat_bp

app.register_blueprint(auth_bp, url_prefix='/api')
app.register_blueprint(onboarding_bp, url_prefix='/api')
app.register_blueprint(score_bp, url_prefix='/api')
app.register_blueprint(fire_bp, url_prefix='/api')
app.register_blueprint(tax_bp, url_prefix='/api')
app.register_blueprint(dashboard_bp, url_prefix='/api')
app.register_blueprint(chat_bp, url_prefix='/api')

# Smart Buy Lens (Phase 7)
try:
    from routes.smart_buy import smart_buy_bp
    app.register_blueprint(smart_buy_bp, url_prefix='/api')
except ImportError:
    pass  # smart_buy.py not created yet

# Markets (Phase 8)
try:
    from routes.markets import markets_bp
    app.register_blueprint(markets_bp, url_prefix='/api')
except ImportError:
    pass

# ── Health Check ─────────────────────────────────────────────────────────────
@app.route('/ping')
def ping():
    return jsonify({'status': 'ok', 'version': '4.0'}), 200

@app.route('/')
def root():
    return jsonify({
        'app': 'FinIQ Backend',
        'version': '4.0',
        'status': 'running',
        'endpoints': [
            '/ping', '/api/auth/verify', '/api/onboarding/save',
            '/api/score/calculate', '/api/fire/plan', '/api/tax/compare',
            '/api/user/dashboard', '/api/chat/message', '/api/smart-buy/compare',
            '/api/markets/overview', '/api/markets/movers',
            '/api/markets/watchlist-quotes', '/api/markets/search',
            '/api/markets/artha-insight',
        ]
    }), 200

# ── Run ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = not IS_PRODUCTION
    print(f'🚀 FinIQ Backend v4.0 starting on port {port} (debug={debug})')
    app.run(host='0.0.0.0', port=port, debug=debug)
