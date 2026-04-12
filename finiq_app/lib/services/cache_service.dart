import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// R3: UID-scoped Hive cache for dashboard data.
/// All keys are prefixed with the current user's UID to prevent
/// User B from seeing User A's financial data on shared devices.
class CacheService {
  CacheService._();

  static const String _boxName = 'finiq_cache';
  static const Duration freshDuration = Duration(hours: 24);

  static bool _initialized = false;
  static String _currentUid = '';

  /// Initialize Hive. Call once in main().
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    _initialized = true;
  }

  static Box get _box => Hive.box(_boxName);

  /// Set the current user's UID. Call this on login.
  /// All subsequent cache operations will be scoped to this UID.
  static void setCurrentUser(String uid) {
    _currentUid = uid;
  }

  /// Prefix a key with the current UID for isolation.
  static String _scopedKey(String key) {
    if (_currentUid.isEmpty) return key;
    return '${_currentUid}_$key';
  }

  // ── Generic cache operations ─────────────────────────────

  /// Save a JSON-serializable map to cache (UID-scoped).
  static Future<void> putJson(String key, Map<String, dynamic> data) async {
    final scoped = _scopedKey(key);
    await _box.put(scoped, jsonEncode(data));
    await _box.put('${scoped}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get a cached JSON map (UID-scoped). Returns null if not found.
  static Map<String, dynamic>? getJson(String key) {
    final raw = _box.get(_scopedKey(key)) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if cache entry is still fresh (within freshDuration).
  static bool isFresh(String key) {
    final ts = _box.get('${_scopedKey(key)}_ts') as int?;
    if (ts == null) return false;
    final cached = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cached) < freshDuration;
  }

  /// Get cached data only if it's still fresh.
  static Map<String, dynamic>? getFreshJson(String key) {
    if (!isFresh(key)) return null;
    return getJson(key);
  }

  /// Delete a specific cache entry (UID-scoped).
  static Future<void> delete(String key) async {
    final scoped = _scopedKey(key);
    await _box.delete(scoped);
    await _box.delete('${scoped}_ts');
  }

  /// Clear all cache for the current user.
  /// Call this on LOGOUT — before FirebaseAuth.signOut().
  static Future<void> clearCurrentUserData() async {
    if (_currentUid.isEmpty) return;
    final prefix = '${_currentUid}_';
    final keysToDelete = _box.keys.where(
        (k) => k.toString().startsWith(prefix)).toList();
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
    _currentUid = '';
  }

  /// Clear all cache (nuclear option — for dev/debug).
  static Future<void> clearAll() async {
    await _box.clear();
    _currentUid = '';
  }

  // ── Domain-specific helpers ──────────────────────────────

  static const String _dashboardKey = 'dashboard_data';
  static const String _healthKey = 'health_score';
  static const String _fireKey = 'fire_plan';
  static const String _taxKey = 'tax_report';

  /// Cache the full dashboard response.
  static Future<void> cacheDashboard(Map<String, dynamic> data) async {
    await putJson(_dashboardKey, data);
  }

  /// Get cached dashboard (even if stale — for offline).
  static Map<String, dynamic>? getCachedDashboard() => getJson(_dashboardKey);

  /// Get fresh dashboard (null if stale).
  static Map<String, dynamic>? getFreshDashboard() => getFreshJson(_dashboardKey);

  /// Check if we have ANY cached dashboard (for offline mode).
  static bool hasCachedDashboard() => getJson(_dashboardKey) != null;

  /// Cache individual reports.
  static Future<void> cacheHealth(Map<String, dynamic> data) async => putJson(_healthKey, data);
  static Future<void> cacheFire(Map<String, dynamic> data) async => putJson(_fireKey, data);
  static Future<void> cacheTax(Map<String, dynamic> data) async => putJson(_taxKey, data);

  static Map<String, dynamic>? getCachedHealth() => getJson(_healthKey);
  static Map<String, dynamic>? getCachedFire() => getJson(_fireKey);
  static Map<String, dynamic>? getCachedTax() => getJson(_taxKey);
}
