import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ── ENVIRONMENT TOGGLE ──────────────────────────────────
  // Set to true before Railway deploy, false for local dev
  static const bool isProduction = false;

  // ── ENVIRONMENTS ────────────────────────────────────────
  static const String _prodBaseUrl =
      'https://finiq-backend-production.up.railway.app';

  // Physical device on same Wi-Fi — use laptop's LAN IP
  // Find via: ipconfig (Windows) / ifconfig (Mac/Linux)
  static const String _devBaseUrl = 'http://10.240.191.92:5000';

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
