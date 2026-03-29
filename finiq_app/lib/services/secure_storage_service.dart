import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'auth_token';
  static const _keyUserProfile = 'user_profile_json';
  static const _keyOnboardingData = 'onboarding_data';

  // ─── Token ───────────────────────────────────────────────
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // ─── User Profile ─────────────────────────────────────────
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: _keyUserProfile, value: jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = await _storage.read(key: _keyUserProfile);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ─── Onboarding Data ─────────────────────────────────────
  Future<void> saveOnboardingData(Map<String, dynamic> data) async {
    await _storage.write(key: _keyOnboardingData, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getOnboardingData() async {
    final raw = await _storage.read(key: _keyOnboardingData);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ─── Clear All ────────────────────────────────────────────
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
