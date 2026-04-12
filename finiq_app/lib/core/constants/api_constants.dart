import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ── ENVIRONMENT TOGGLE ──────────────────────────────────
  // Set to true before Railway deploy, false for local dev
  static const bool isProduction = true;

  // ── ENVIRONMENTS ────────────────────────────────────────
  static const String _prodBaseUrl =
      'https://finiq-backend-production.up.railway.app';

  // R10: Dev URL uses env-based override, no private IP in release binary.
  // For local dev, run: flutter run --dart-define=DEV_API_URL=http://your.ip:5000
  static const String _devBaseUrl = String.fromEnvironment(
    'DEV_API_URL',
    defaultValue: 'http://localhost:5000',
  );

  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;

  // ── ENDPOINTS ───────────────────────────────────────────
  static const String onboardingSave = '/api/onboarding/save';
  static const String dashboard = '/api/user/dashboard';
  static const String healthScore = '/api/score/calculate';
  static const String firePlan = '/api/fire/plan';
  static const String taxCompare = '/api/tax/compare';
  static const String chatMessage = '/api/chat/message';
  static const String expenseAnalyse = '/api/expenses/analyse';
  static const String smartBuyCompare = '/api/smart-buy/compare';
  static const String ping = '/ping';

  // ── TIMEOUTS ────────────────────────────────────────────
  static const int connectTimeoutSec = 30;
  static const int receiveTimeoutSec = 120;

  // Demo mode — should ALWAYS be false for production
  static const bool demoMode = false;
}
