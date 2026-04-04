"""
FinIQ Markets API — Real-time Indian market data (10x Upgrade)
Data: Yahoo Finance (yfinance)
Insights: Gemini 2.5 Flash with Google Search grounding
"""

import os
import json
import time
import re as _re
from datetime import datetime
from flask import Blueprint, jsonify, request

import yfinance as yf
import pytz

markets_bp = Blueprint('markets', __name__)

# ═══════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════

INDICES = {
    "NIFTY_50":   "^NSEI",
    "SENSEX":     "^BSESN",
    "NIFTY_BANK": "^NSEBANK",
    "NIFTY_IT":   "^CNXIT",
    "NIFTY_MID":  "^NSEMDCP50",
}

SECTORS = {
    "Auto":    "^CNXAUTO",
    "FMCG":    "^CNXFMCG",
    "Pharma":  "^CNXPHARMA",
    "Metal":   "^CNXMETAL",
    "Realty":  "^CNXREALTY",
    "Energy":  "^CNXENERGY",
}

# Sector → top stocks mapping for sector detail sheet
SECTOR_STOCKS = {
    "Auto":    {"Maruti": "MARUTI.NS", "Tata Motors": "TATAMOTORS.NS", "M&M": "M&M.NS", "Bajaj Auto": "BAJAJ-AUTO.NS", "Eicher Motors": "EICHERMOT.NS"},
    "FMCG":    {"HUL": "HINDUNILVR.NS", "ITC": "ITC.NS", "Nestle": "NESTLEIND.NS", "Brit Industries": "BRITANNIA.NS", "Tata Consumer": "TATACONSUM.NS"},
    "Pharma":  {"Sun Pharma": "SUNPHARMA.NS", "Dr Reddy": "DRREDDY.NS", "Cipla": "CIPLA.NS", "Divis Lab": "DIVISLAB.NS", "Apollo Hosp": "APOLLOHOSP.NS"},
    "Metal":   {"Tata Steel": "TATASTEEL.NS", "JSW Steel": "JSWSTEEL.NS", "Hindalco": "HINDALCO.NS", "Coal India": "COALINDIA.NS", "ONGC": "ONGC.NS"},
    "Realty":  {"DLF": "DLF.NS", "Godrej Prop": "GODREJPROP.NS", "Oberoi Realty": "OBEROIRLTY.NS", "Prestige": "PRESTIGE.NS", "Phoenix": "PHOENIXLTD.NS"},
    "Energy":  {"Reliance": "RELIANCE.NS", "NTPC": "NTPC.NS", "Power Grid": "POWERGRID.NS", "BPCL": "BPCL.NS", "ONGC": "ONGC.NS"},
}

GLOBAL_INDICES = {
    "S&P 500":  "^GSPC",
    "Nasdaq":   "^IXIC",
    "Nikkei":   "^N225",
    "Hang Seng":"^HSI",
    "FTSE":     "^FTSE",
}

NIFTY50_STOCKS = {
    "Reliance":      "RELIANCE.NS",
    "TCS":           "TCS.NS",
    "HDFC Bank":     "HDFCBANK.NS",
    "Infosys":       "INFY.NS",
    "ICICI Bank":    "ICICIBANK.NS",
    "HUL":           "HINDUNILVR.NS",
    "ITC":           "ITC.NS",
    "Kotak Bank":    "KOTAKBANK.NS",
    "L&T":           "LT.NS",
    "Bajaj Finance": "BAJFINANCE.NS",
    "Wipro":         "WIPRO.NS",
    "Asian Paints":  "ASIANPAINT.NS",
    "Maruti":        "MARUTI.NS",
    "Titan":         "TITAN.NS",
    "Sun Pharma":    "SUNPHARMA.NS",
    "Nestle":        "NESTLEIND.NS",
    "M&M":           "M&M.NS",
    "Axis Bank":     "AXISBANK.NS",
    "HCL Tech":      "HCLTECH.NS",
    "ONGC":          "ONGC.NS",
    "SBI":           "SBIN.NS",
    "Bharti Airtel": "BHARTIARTL.NS",
    "Adani Ent":     "ADANIENT.NS",
    "Bajaj Finserv": "BAJAJFINSV.NS",
    "Power Grid":    "POWERGRID.NS",
    "NTPC":          "NTPC.NS",
    "Tata Motors":   "TATAMOTORS.NS",
    "Tata Steel":    "TATASTEEL.NS",
    "Coal India":    "COALINDIA.NS",
    "JSW Steel":     "JSWSTEEL.NS",
    "IndusInd Bank": "INDUSINDBK.NS",
    "Tech Mahindra": "TECHM.NS",
    "Grasim":        "GRASIM.NS",
    "Dr Reddy":      "DRREDDY.NS",
    "Cipla":         "CIPLA.NS",
    "BPCL":          "BPCL.NS",
    "Eicher Motors": "EICHERMOT.NS",
    "Divis Lab":     "DIVISLAB.NS",
    "Hindalco":      "HINDALCO.NS",
    "Hero Moto":     "HEROMOTOCO.NS",
    "Apollo Hosp":   "APOLLOHOSP.NS",
    "UPL":           "UPL.NS",
    "Tata Consumer": "TATACONSUM.NS",
    "Brit Industries":"BRITANNIA.NS",
    "Shriram Finance":"SHRIRAMFIN.NS",
    "Adani Ports":   "ADANIPORTS.NS",
    "Bajaj Auto":    "BAJAJ-AUTO.NS",
    "Ultratech":     "ULTRACEMCO.NS",
    "HDFC Life":     "HDFCLIFE.NS",
    "SBI Life":      "SBILIFE.NS",
    "Dmart":         "DMART.NS",
}


# ═══════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════

IST = pytz.timezone('Asia/Kolkata')


def is_market_open() -> bool:
    now = datetime.now(IST)
    if now.weekday() >= 5:
        return False
    market_open = now.replace(hour=9, minute=15, second=0, microsecond=0)
    market_close = now.replace(hour=15, minute=30, second=0, microsecond=0)
    return market_open <= now <= market_close


def fetch_quote(symbol: str, display_name: str = '') -> dict:
    """Fetch a single quote from Yahoo Finance using fast_info."""
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.fast_info

        current = float(info.last_price or 0)
        prev_close = float(info.previous_close or 0)
        change = current - prev_close
        change_pct = (change / prev_close * 100) if prev_close > 0 else 0

        sparkline = []
        try:
            hist = ticker.history(period='1d', interval='5m')
            if hist is not None and not hist.empty:
                closes = hist['Close'].tail(12).tolist()
                sparkline = [round(float(v), 2) for v in closes]
        except Exception:
            pass

        return {
            'symbol': symbol,
            'displayName': display_name or symbol,
            'current': round(current, 2),
            'change': round(change, 2),
            'changePct': round(change_pct, 2),
            'prevClose': round(prev_close, 2),
            'high': round(float(info.day_high or 0), 2),
            'low': round(float(info.day_low or 0), 2),
            'volume': int(info.three_month_average_volume or 0),
            'sparkline': sparkline,
            'isPositive': change >= 0,
        }
    except Exception as e:
        print(f'[MARKETS] Error fetching {symbol}: {e}')
        return {
            'symbol': symbol,
            'displayName': display_name or symbol,
            'current': 0, 'change': 0, 'changePct': 0,
            'prevClose': 0, 'high': 0, 'low': 0,
            'volume': 0, 'sparkline': [], 'isPositive': True,
            'error': str(e),
        }


def fetch_stock_detail(symbol: str, display_name: str = '') -> dict:
    """Fetch extended stock data (52-week, PE, market cap) using ticker.info.
    Only called once per stock detail view — heavier but richer data."""
    base = fetch_quote(symbol, display_name)
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.info or {}
        base['week52High'] = round(float(info.get('fiftyTwoWeekHigh', 0) or 0), 2)
        base['week52Low'] = round(float(info.get('fiftyTwoWeekLow', 0) or 0), 2)
        pe = info.get('trailingPE')
        base['pe'] = round(float(pe), 1) if pe else None
        mc = info.get('marketCap')
        base['marketCap'] = int(mc) if mc else None
        base['sector'] = info.get('sector', '')
    except Exception as e:
        print(f'[MARKETS] Detail fetch error {symbol}: {e}')
        base['week52High'] = 0
        base['week52Low'] = 0
        base['pe'] = None
        base['marketCap'] = None
        base['sector'] = ''
    return base


def _parse_json_safe(text):
    if not text:
        return {}
    text = _re.sub(r'```(?:json)?\n?(.*?)\n?```', r'\1', text, flags=_re.DOTALL)
    text = text.strip()
    start = text.find('{')
    end = text.rfind('}') + 1
    if start == -1 or end == 0:
        # Try array
        start = text.find('[')
        end = text.rfind(']') + 1
        if start == -1 or end == 0:
            return {}
        try:
            return json.loads(text[start:end])
        except json.JSONDecodeError:
            return {}
    try:
        return json.loads(text[start:end])
    except json.JSONDecodeError:
        return {}


# ── Caches ──
_overview_cache = {'data': None, 'ts': 0}
OVERVIEW_TTL = 60

_movers_cache = {'data': None, 'ts': 0}
MOVERS_TTL = 90

_artha_cache = {'data': None, 'ts': 0}
ARTHA_TTL = 1800

_news_cache = {'data': None, 'ts': 0}
NEWS_TTL = 900  # 15 minutes

_sector_cache = {}  # sector_name -> {data, ts}
SECTOR_TTL = 120


# ═══════════════════════════════════════════════════════════
# ENDPOINT 1: GET /markets/overview
# Now includes global indices
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/overview', methods=['GET'])
def get_market_overview():
    now = time.time()
    if _overview_cache['data'] and (now - _overview_cache['ts'] < OVERVIEW_TTL):
        return jsonify(_overview_cache['data']), 200

    market_open = is_market_open()

    indices_data = {}
    for name, symbol in INDICES.items():
        display = name.replace('_', ' ')
        indices_data[name] = fetch_quote(symbol, display)

    sectors_data = {}
    for name, symbol in SECTORS.items():
        sectors_data[name] = fetch_quote(symbol, name)

    # Global indices
    global_data = {}
    for name, symbol in GLOBAL_INDICES.items():
        try:
            global_data[name] = fetch_quote(symbol, name)
        except Exception:
            global_data[name] = {'displayName': name, 'current': 0, 'changePct': 0, 'isPositive': True, 'error': 'unavailable'}

    nifty_pct = indices_data.get('NIFTY_50', {}).get('changePct', 0)
    if nifty_pct > 0.5:
        sentiment = 'BULLISH'
    elif nifty_pct < -0.5:
        sentiment = 'BEARISH'
    else:
        sentiment = 'NEUTRAL'

    result = {
        'isMarketOpen': market_open,
        'lastUpdated': datetime.now(IST).isoformat(),
        'sentiment': sentiment,
        'indices': indices_data,
        'sectors': sectors_data,
        'global': global_data,
    }

    _overview_cache['data'] = result
    _overview_cache['ts'] = now
    return jsonify(result), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 2: GET /markets/movers
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/movers', methods=['GET'])
def get_market_movers():
    now = time.time()
    if _movers_cache['data'] and (now - _movers_cache['ts'] < MOVERS_TTL):
        return jsonify(_movers_cache['data']), 200

    results = []
    for name, symbol in NIFTY50_STOCKS.items():
        quote = fetch_quote(symbol, name)
        results.append(quote)

    valid = [r for r in results if 'error' not in r]
    gainers = sorted(valid, key=lambda x: x['changePct'], reverse=True)[:5]
    losers = sorted(valid, key=lambda x: x['changePct'])[:5]

    result = {'gainers': gainers, 'losers': losers}
    _movers_cache['data'] = result
    _movers_cache['ts'] = now
    return jsonify(result), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 3: POST /markets/watchlist-quotes
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/watchlist-quotes', methods=['POST'])
def get_watchlist_quotes():
    data = request.json or {}
    symbols = data.get('symbols', [])
    quotes = {}
    for symbol in symbols[:20]:
        display = symbol
        for name, sym in NIFTY50_STOCKS.items():
            if sym == symbol:
                display = name
                break
        quotes[symbol] = fetch_quote(symbol, display)
    return jsonify({'quotes': quotes}), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 4: GET /markets/search?q=QUERY
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/search', methods=['GET'])
def search_stocks():
    query = (request.args.get('q', '') or '').lower().strip()
    if not query:
        return jsonify({'results': []}), 200

    results = []
    for name, symbol in NIFTY50_STOCKS.items():
        if query in name.lower() or query in symbol.lower().replace('.ns', ''):
            results.append({'displayName': name, 'symbol': symbol})
    return jsonify({'results': results[:10]}), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 5: GET /markets/artha-insight
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/artha-insight', methods=['GET'])
def get_artha_market_insight():
    now = time.time()
    if _artha_cache['data'] and (now - _artha_cache['ts'] < ARTHA_TTL):
        return jsonify(_artha_cache['data']), 200

    fire_corpus = float(request.args.get('fire_corpus', 0))
    monthly_sip = float(request.args.get('monthly_sip', 0))
    risk_appetite = request.args.get('risk_appetite', 'moderate')

    nifty = fetch_quote('^NSEI', 'Nifty 50')
    nifty_pct = nifty.get('changePct', 0)

    prompt = f"""You are Artha, FinIQ's AI financial mentor for Indian salaried professionals.

TODAY'S MARKET:
Nifty 50 is {"up" if nifty_pct >= 0 else "down"} {abs(nifty_pct):.2f}% today at {nifty.get('current', 0):,.0f}.

USER PROFILE:
- FIRE corpus target: ₹{fire_corpus:,.0f}
- Monthly SIP: ₹{monthly_sip:,.0f}
- Risk appetite: {risk_appetite}

Search for today's top Indian market news and generate insights for this user.
Be specific with numbers. Be concise. No fluff.

Return ONLY this JSON:
{{
  "marketSummary": "2 sentences max. What happened in Indian markets today and why.",
  "fireImpact": "1 sentence. How today's market movement affects their FIRE corpus or SIP. Use actual % numbers.",
  "sipAdvice": "1 sentence. What this means for their SIP this month. Be specific.",
  "sentiment": "BULLISH|BEARISH|NEUTRAL",
  "lastUpdated": "{datetime.now(IST).strftime('%d %b %Y')}",
  "sectorInsights": {{
    "Auto": "1 sentence about auto sector today",
    "FMCG": "1 sentence about FMCG sector today",
    "Pharma": "1 sentence about pharma sector today",
    "Metal": "1 sentence about metals sector today",
    "Realty": "1 sentence about realty sector today",
    "Energy": "1 sentence about energy sector today"
  }}
}}
Return ONLY valid JSON. No markdown. No explanation."""

    fallback = {
        'marketSummary': f'Nifty 50 {"gained" if nifty_pct >= 0 else "lost"} {abs(nifty_pct):.2f}% today, closing at ₹{nifty.get("current", 0):,.0f}.',
        'fireImpact': 'Continue your SIP — short-term movements don\'t change your long-term FIRE timeline.',
        'sipAdvice': 'Stay consistent with your monthly SIP allocation regardless of daily market moves.',
        'sentiment': 'BULLISH' if nifty_pct > 0.5 else ('BEARISH' if nifty_pct < -0.5 else 'NEUTRAL'),
        'lastUpdated': datetime.now(IST).strftime('%d %b %Y'),
        'sectorInsights': {},
    }

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
        config_kwargs = {'temperature': 0.3}
        try:
            search_tool = types.Tool(google_search=types.GoogleSearch())
            config_kwargs['tools'] = [search_tool]
        except Exception:
            pass

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(**config_kwargs)
        )

        data = _parse_json_safe(response.text.strip() if response.text else '')
        if data and 'marketSummary' in data:
            for key in fallback:
                if key not in data:
                    data[key] = fallback[key]
            _artha_cache['data'] = data
            _artha_cache['ts'] = now
            return jsonify(data), 200
        else:
            _artha_cache['data'] = fallback
            _artha_cache['ts'] = now
            return jsonify(fallback), 200

    except Exception as e:
        print(f'[MARKETS] Artha insight error: {e}')
        return jsonify(fallback), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 6: GET /markets/news
# Market news via Gemini with Google Search grounding
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/news', methods=['GET'])
def get_market_news():
    now = time.time()
    if _news_cache['data'] and (now - _news_cache['ts'] < NEWS_TTL):
        return jsonify(_news_cache['data']), 200

    prompt = """Search for the 5 most important Indian stock market news stories from today.
Focus on: Nifty, Sensex, RBI, FII/DII activity, major corporate results, sector moves.

Return ONLY a JSON array of 5 items:
[
  {
    "headline": "max 80 chars",
    "source": "e.g. Economic Times, Mint, Moneycontrol",
    "timeAgo": "e.g. 2 hours ago",
    "sentiment": "POSITIVE|NEGATIVE|NEUTRAL"
  }
]
Return ONLY the JSON array. No markdown. No explanation."""

    fallback_news = [
        {"headline": "Markets trade mixed amid global cues and FII activity", "source": "Market Update", "timeAgo": "Today", "sentiment": "NEUTRAL"},
    ]

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
        config_kwargs = {'temperature': 0.3}
        try:
            search_tool = types.Tool(google_search=types.GoogleSearch())
            config_kwargs['tools'] = [search_tool]
        except Exception:
            pass

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(**config_kwargs)
        )

        text = response.text.strip() if response.text else ''
        # Parse JSON array
        text = _re.sub(r'```(?:json)?\n?(.*?)\n?```', r'\1', text, flags=_re.DOTALL).strip()
        start = text.find('[')
        end = text.rfind(']') + 1
        if start != -1 and end > 0:
            data = json.loads(text[start:end])
            if isinstance(data, list) and len(data) > 0:
                result = {'news': data[:5]}
                _news_cache['data'] = result
                _news_cache['ts'] = now
                return jsonify(result), 200

        result = {'news': fallback_news}
        _news_cache['data'] = result
        _news_cache['ts'] = now
        return jsonify(result), 200

    except Exception as e:
        print(f'[MARKETS] News error: {e}')
        return jsonify({'news': fallback_news}), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 7: GET /markets/sector/<sector_name>
# Top stocks in a given sector
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/sector/<sector_name>', methods=['GET'])
def get_sector_detail(sector_name):
    now = time.time()
    cached = _sector_cache.get(sector_name)
    if cached and (now - cached['ts'] < SECTOR_TTL):
        return jsonify(cached['data']), 200

    stocks_map = SECTOR_STOCKS.get(sector_name, {})
    if not stocks_map:
        return jsonify({'stocks': [], 'sector': sector_name}), 200

    stocks = []
    for name, symbol in stocks_map.items():
        quote = fetch_quote(symbol, name)
        stocks.append(quote)

    stocks.sort(key=lambda x: x['changePct'], reverse=True)
    result = {'stocks': stocks, 'sector': sector_name}
    _sector_cache[sector_name] = {'data': result, 'ts': now}
    return jsonify(result), 200


# ═══════════════════════════════════════════════════════════
# ENDPOINT 8: GET /markets/stock-detail?symbol=RELIANCE.NS
# Extended stock data for detail sheet
# ═══════════════════════════════════════════════════════════

@markets_bp.route('/markets/stock-detail', methods=['GET'])
def get_stock_detail():
    symbol = request.args.get('symbol', '')
    if not symbol:
        return jsonify({'error': 'Symbol required'}), 400

    display = symbol
    for name, sym in NIFTY50_STOCKS.items():
        if sym == symbol:
            display = name
            break

    data = fetch_stock_detail(symbol, display)
    return jsonify(data), 200
