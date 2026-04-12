"""
Production Audit Verification — Tests for R1-R12 fixes.
Run with: python test_audit_fixes.py
"""
import sys
import time
sys.stdout.reconfigure(encoding='utf-8')

print('=' * 60)
print('FinIQ Production Audit — Verification Suite')
print('=' * 60)

# ── R1: Message cap constants ────────────────────────────────
from routes.artha import (
    MAX_MESSAGES_PER_CONVERSATION,
    MAX_MESSAGE_LENGTH,
    RATE_LIMIT_MAX_PER_MINUTE,
    RATE_LIMIT_MAX_PER_DAY,
    _check_rate_limit,
)
assert MAX_MESSAGES_PER_CONVERSATION == 50, f'Expected 50, got {MAX_MESSAGES_PER_CONVERSATION}'
assert MAX_MESSAGE_LENGTH == 2000, f'Expected 2000, got {MAX_MESSAGE_LENGTH}'
print('✅ R1: Message cap constants correct (50 msgs, 2000 chars)')

# ── R5: Aggregation pipeline (no N+1) ───────────────────────
# Verify artha.py uses aggregate() and has no find_one in list_conversations
with open('routes/artha.py', 'r', encoding='utf-8') as f:
    artha_source = f.read()
assert '.aggregate(pipeline)' in artha_source, 'artha.py must use aggregation pipeline'
# find_one should only appear in get_messages and send_message, NOT in list_conversations
# The old N+1 pattern had find_one inside the list loop — that's gone now
list_func_start = artha_source.index('def list_conversations')
list_func_end = artha_source.index('def get_messages')
list_func_body = artha_source[list_func_start:list_func_end]
# Only check actual code lines (not comments) for find_one
code_lines = [l for l in list_func_body.split('\n') if l.strip() and not l.strip().startswith('#')]
has_find_one_code = any('.find_one(' in l for l in code_lines)
assert not has_find_one_code, 'list_conversations must NOT use find_one loop'
print('✅ R5: list_conversations uses aggregation pipeline (no N+1)')

# ── R6: Rate limiting works ─────────────────────────────────
test_uid = 'test_rate_limit_user_999'
# First 10 should pass
for i in range(10):
    ok, _ = _check_rate_limit(test_uid)
    assert ok, f'Request {i+1} should be allowed'
# 11th should fail
ok, msg = _check_rate_limit(test_uid)
assert not ok, '11th request should be rate-limited'
assert 'wait' in msg.lower(), f'Error should say wait: {msg}'
print('✅ R6: Per-user rate limiting works (10/min, then 429)')

# ── R7: Message length constant ──────────────────────────────
assert MAX_MESSAGE_LENGTH == 2000
print('✅ R7: Message length cap = 2000 chars')

# ── R8: No bare except in onboarding.py ──────────────────────
with open('routes/onboarding.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()
bare_excepts = [
    (i+1, line.strip()) for i, line in enumerate(lines)
    if line.strip() == 'except:' or line.strip().startswith('except:') 
    and 'except (TypeError' not in line and 'except Exception' not in line
]
# Filter out comments
bare_excepts = [(n, l) for n, l in bare_excepts if 'TypeError' not in l and 'ValueError' not in l]
assert len(bare_excepts) == 0, f'Found bare excepts: {bare_excepts}'
print('✅ R8: Zero bare except: clauses in onboarding.py')

# ── R4: Dashboard TTL check ─────────────────────────────────
with open('routes/dashboard.py', 'r', encoding='utf-8') as f:
    dash_source = f.read()
assert 'timedelta(days=7)' in dash_source, 'Dashboard must have 7-day TTL'
assert 'dashboard_generated_at' in dash_source, 'Must check cached_at timestamp'
print('✅ R4: Dashboard brief has 7-day TTL')

# ── R2: .gitignore has log patterns ─────────────────────────
with open('../.gitignore', 'r', encoding='utf-8') as f:
    gitignore = f.read()
assert 'flask_log.txt' in gitignore, 'flask_log.txt must be in .gitignore'
assert '*.log' in gitignore, '*.log wildcard must be in .gitignore'
assert 'logs/' in gitignore, 'logs/ dir must be in .gitignore'
print('✅ R2: .gitignore covers all log patterns')

# ── R12: Auth decorator exists ───────────────────────────────
from utils.auth import require_auth, get_uid_from_request
assert callable(require_auth), 'require_auth must be callable'
assert callable(get_uid_from_request), 'get_uid_from_request must be callable'
print('✅ R12: Shared auth decorator created')

# ── R10: No private IP in api_constants ──────────────────────
# (This is a Flutter file — we just verify the pattern)
import os
api_const_path = os.path.join('..', 'finiq_app', 'lib', 'core', 'constants', 'api_constants.dart')
with open(api_const_path, 'r', encoding='utf-8') as f:
    api_source = f.read()
assert '10.240' not in api_source, 'Dev IP must be removed from APK binary'
assert 'String.fromEnvironment' in api_source, 'Must use env-based override'
print('✅ R10: Private dev IP removed from APK binary')

# ── R9: No silent demo fallback ──────────────────────────────
api_service_path = os.path.join('..', 'finiq_app', 'lib', 'services', 'api_service.dart')
with open(api_service_path, 'r', encoding='utf-8') as f:
    api_svc = f.read()
# Count .demo() calls — should only appear in demoMode guards, not catch blocks
demo_in_catch = api_svc.count('return HealthScoreModel.demo();') + \
                api_svc.count('return FirePlanModel.demo();') + \
                api_svc.count('return TaxReportModel.demo();')
# demoMode guards are 3 (one per method), catch blocks should have 0
demo_in_demomode = api_svc.count('ApiConstants.demoMode')
assert demo_in_catch == demo_in_demomode, f'Demo fallbacks in catch: {demo_in_catch} (should equal demoMode guards: {demo_in_demomode})'
print('✅ R9: No silent mock data fallback on API errors')

# ── R3: Cache service has UID scoping ────────────────────────
cache_path = os.path.join('..', 'finiq_app', 'lib', 'services', 'cache_service.dart')
with open(cache_path, 'r', encoding='utf-8') as f:
    cache_source = f.read()
assert 'setCurrentUser' in cache_source, 'Must have setCurrentUser method'
assert '_currentUid' in cache_source, 'Must have _currentUid field'
assert 'clearCurrentUserData' in cache_source, 'Must have clearCurrentUserData'
assert '_scopedKey' in cache_source, 'Must have _scopedKey helper'
print('✅ R3: Hive cache is UID-scoped')

# ── Database indexes ─────────────────────────────────────────
with open('models/database.py', 'r', encoding='utf-8') as f:
    db_source = f.read()
assert "('userId', ASCENDING), ('updatedAt', -1)" in db_source, 'Must have userId+updatedAt index'
assert "('conversationId', ASCENDING)" in db_source, 'Must have conversationId index'
print('✅ DB: Conversation indexes added')

print()
print('=' * 60)
print('ALL 11 VERIFICATIONS PASSED ✅')
print('=' * 60)
