import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UID-prefixed SharedPreferences wrapper.
/// Every key is stored as `{uid}_{key}` to prevent cross-user data contamination.
/// Global keys (like language) are stored without prefix.
class UserPrefsService {
  UserPrefsService._();

  static SharedPreferences? _prefs;

  /// Get the current Firebase UID (empty string if not logged in)
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Prefixed key for per-user data
  static String _key(String key) {
    final uid = _uid;
    if (uid.isEmpty) return key; // fallback to unprefixed
    return '${uid}_$key';
  }

  /// Initialize (call once at app start or lazily)
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Global keys (NOT prefixed with UID) ──────────────────────────────────

  static const _globalKeys = {
    'app_language',
  };

  static String _resolveKey(String key) {
    if (_globalKeys.contains(key)) return key;
    return _key(key);
  }

  // ── Readers ──────────────────────────────────────────────────────────────

  static Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(_resolveKey(key));
  }

  static Future<int?> getInt(String key) async {
    final prefs = await _getPrefs();
    final k = _resolveKey(key);
    return prefs.containsKey(k) ? prefs.getInt(k) : null;
  }

  static Future<double?> getDouble(String key) async {
    final prefs = await _getPrefs();
    final k = _resolveKey(key);
    return prefs.containsKey(k) ? prefs.getDouble(k) : null;
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await _getPrefs();
    final k = _resolveKey(key);
    return prefs.containsKey(k) ? prefs.getBool(k) : null;
  }

  // ── Writers ──────────────────────────────────────────────────────────────

  static Future<void> setString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(_resolveKey(key), value);
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_resolveKey(key), value);
  }

  static Future<void> setDouble(String key, double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_resolveKey(key), value);
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_resolveKey(key), value);
  }

  static Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(_resolveKey(key));
  }

  // ── Bulk operations ──────────────────────────────────────────────────────

  /// Clear ALL keys for the current user (used on sign-out)
  static Future<void> clearCurrentUserData() async {
    final prefs = await _getPrefs();
    final uid = _uid;
    if (uid.isEmpty) return;

    final prefix = '${uid}_';
    final allKeys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in allKeys) {
      await prefs.remove(key);
    }
  }

  /// Check if onboarding is complete for current user
  static Future<bool> isOnboardingComplete() async {
    final val = await getBool('onboarding_complete');
    return val ?? false;
  }

  /// Mark onboarding complete for current user
  static Future<void> setOnboardingComplete(bool value) async {
    await setBool('onboarding_complete', value);
  }
}
