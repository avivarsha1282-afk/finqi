"""
FinIQ Gemini Response Cache
Prevents redundant Gemini API calls by caching responses with TTLs.
"""
import time
import threading

_cache = {}
_lock = threading.Lock()


def get_cached(key: str, ttl_seconds: int):
    """Return cached data if within TTL, else None."""
    with _lock:
        entry = _cache.get(key)
        if entry and (time.time() - entry['ts'] < ttl_seconds):
            print(f"[CACHE] HIT for '{key}' (age: {time.time() - entry['ts']:.0f}s / {ttl_seconds}s TTL)")
            return entry['data']
    return None


def set_cached(key: str, data):
    """Store data with current timestamp."""
    with _lock:
        _cache[key] = {'data': data, 'ts': time.time()}
        print(f"[CACHE] SET '{key}'")


def is_valid(key: str, ttl_seconds: int) -> bool:
    """Check if cache entry exists and is within TTL."""
    return get_cached(key, ttl_seconds) is not None


def invalidate(key: str):
    """Remove a specific cache entry."""
    with _lock:
        _cache.pop(key, None)
        print(f"[CACHE] INVALIDATED '{key}'")


# ── TTL Constants (seconds) ──────────────────────────────
WEEKLY_BRIEF_TTL = 604800   # 7 days
NEWS_TTL         = 1800     # 30 minutes
IPO_TTL          = 21600    # 6 hours
ARTHA_INSIGHT_TTL = 1800    # 30 minutes
# artha_chat     = NO CACHE (always fresh)
# smart_buy      = NO CACHE (always fresh)
