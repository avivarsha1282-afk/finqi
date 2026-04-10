"""
FinIQ Gemini API Key Pool with:
  - Multiple API key rotation
  - Model cascade fallback
  - Exponential backoff on 429 AND 503 errors
  - Inter-request throttle to prevent burst calls
"""
import os
import time
import threading
from google import genai

_api_keys = []
_lock = threading.Lock()
_current_index = 0
_last_call_time = 0.0
_MIN_INTERVAL = 1.0  # Minimum 1 second between Gemini calls

# Model cascade order — try models with most free-tier quota first
DEFAULT_MODEL_CASCADE = [
    'gemini-2.5-flash',       # 20 RPD free tier
    'gemini-2.0-flash',       # 10 RPD free tier
    'gemini-2.0-flash-lite',  # 30 RPD free tier (cheapest)
]


def _init_keys():
    global _api_keys
    if not _api_keys:
        keys_str = os.getenv('GEMINI_API_KEYS')
        if keys_str:
            _api_keys = [k.strip() for k in keys_str.split(',') if k.strip()]

        single_key = os.getenv('GEMINI_API_KEY')
        if single_key and single_key not in _api_keys:
            _api_keys.append(single_key)

        if not _api_keys:
            _api_keys = ['MISSING_KEY']


def get_current_api_key() -> str:
    global _current_index
    _init_keys()
    with _lock:
        return _api_keys[_current_index]


def rotate_api_key():
    global _current_index
    _init_keys()
    with _lock:
        prev = _current_index
        _current_index = (_current_index + 1) % len(_api_keys)
        if prev != _current_index:
            print(f"[GEMINI_POOL] Rotated API Key! Now using key {_current_index + 1} of {len(_api_keys)}")


def _throttle():
    """Enforce minimum interval between Gemini calls to prevent burst."""
    global _last_call_time
    with _lock:
        now = time.time()
        wait = _MIN_INTERVAL - (now - _last_call_time)
        if wait > 0:
            time.sleep(wait)
        _last_call_time = time.time()


def smart_generate(model_cascade=None, contents=None, config=None):
    """Call Gemini with model cascade, key rotation, and exponential backoff.

    Flow:
      1. Throttle to prevent burst calls
      2. For each model in cascade:
         a. Try the call
         b. On 429 OR 503: exponential backoff (2s, 4s, 8s) then retry same model
         c. On 404: skip to next model
      3. After all models fail on a key, rotate to next key and repeat
    """
    _init_keys()
    if model_cascade is None:
        model_cascade = DEFAULT_MODEL_CASCADE
    last_error = ""
    max_key_rotations = len(_api_keys)
    rotations = 0

    while rotations < max_key_rotations:
        for attempt_model in model_cascade:
            # Exponential backoff for 429/503 on this specific model
            for backoff_attempt in range(3):
                _throttle()
                try:
                    client = genai.Client(api_key=get_current_api_key())
                    response = client.models.generate_content(
                        model=attempt_model,
                        contents=contents,
                        config=config
                    )
                    return response
                except Exception as e:
                    err_str = str(e)
                    last_error = err_str
                    print(f"[GEMINI_POOL] {attempt_model} Key {_current_index + 1} "
                          f"attempt {backoff_attempt + 1}: {err_str[:150]}")

                    if '429' in err_str or 'quota' in err_str.lower():
                        # Rate limited — exponential backoff before retrying same model
                        if backoff_attempt < 2:
                            wait = (2 ** backoff_attempt) * 2  # 2s, 4s, 8s
                            print(f"[GEMINI_POOL] Rate limited (429). Backing off {wait}s...")
                            time.sleep(wait)
                            continue
                        else:
                            break
                    elif '503' in err_str or 'UNAVAILABLE' in err_str:
                        # Temporary overload — retry with backoff (NOT skip!)
                        if backoff_attempt < 2:
                            wait = (2 ** backoff_attempt) * 3  # 3s, 6s, 12s (longer for 503)
                            print(f"[GEMINI_POOL] Server overloaded (503). Backing off {wait}s...")
                            time.sleep(wait)
                            continue
                        else:
                            break
                    elif '404' in err_str:
                        # Model not found — skip to next model immediately
                        break
                    else:
                        # Non-retryable error (bad payload, etc.)
                        raise e

        # All models failed on this key — rotate and try again
        print(f"[GEMINI_POOL] Exhausted all models on API key {_current_index + 1}. Rotating...")
        rotate_api_key()
        rotations += 1

    raise Exception(f"All models and API keys exhausted. Last error: {last_error}")


def smart_generate_with_search(model_cascade=None, contents=None, temperature=0.3):
    """Convenience wrapper that adds Google Search grounding tool."""
    from google.genai import types

    if model_cascade is None:
        model_cascade = DEFAULT_MODEL_CASCADE

    config_kwargs = {'temperature': temperature}
    try:
        search_tool = types.Tool(google_search=types.GoogleSearch())
        config_kwargs['tools'] = [search_tool]
    except Exception:
        pass

    config = types.GenerateContentConfig(**config_kwargs)
    return smart_generate(model_cascade, contents, config)
