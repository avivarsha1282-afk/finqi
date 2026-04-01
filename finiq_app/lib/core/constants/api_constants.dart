import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ── ENVIRONMENTS ────────────────────────────────────
  static const String _railway =
      'https://finiq-backend-production.up.railway.app';

  // Physical device via ADB reverse tunnel: 127.0.0.1
  // Run: adb reverse tcp:5000 tcp:5000
  static const String _local = 'http://127.0.0.1:5000';

  // Auto-switch: Release build → Railway, Debug → Railway (change to _local if running Flask locally)
  static String get baseUrl => _railway;

  // ── ENDPOINTS ───────────────────────────────────────
  static const String onboardingSave = '/api/onboarding/save';
  static const String dashboard = '/api/user/dashboard';
  static const String healthScore = '/api/score/calculate';
  static const String firePlan = '/api/fire/plan';
  static const String taxCompare = '/api/tax/compare';
  static const String chatMessage = '/api/chat/message';
  static const String expenseAnalyse = '/api/expenses/analyse';
  static const String smartBuyCompare = '/api/smart-buy/compare';
  static const String ping = '/ping';

  // ── TIMEOUTS ────────────────────────────────────────
  static const int connectTimeoutSec = 10;
  static const int receiveTimeoutSec = 30;

  // Demo mode — should ALWAYS be false for production
  static const bool demoMode = false;
}
