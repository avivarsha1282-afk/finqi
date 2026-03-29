class ApiConstants {
  ApiConstants._();

  // Base URL — Android emulator accesses host machine at 10.0.2.2, NOT localhost
  static const String baseUrl = 'http://10.0.2.2:5000';
  // Production: update to Render URL after deployment
  // static const String baseUrl = 'https://finiq-backend.onrender.com';

  /// Set to true to run without a Flask backend — uses pre-seeded Avinash demo data.
  /// Gemini AI chat still works (only Gemini API key required).
  /// Set to false for full production mode with MongoDB + Firebase.
  static const bool demoMode = false;

  // Timeouts — fail fast so we can show a proper error state
  static const int connectTimeoutSec = 5;
  static const int receiveTimeoutSec = 10;

  // Auth
  static const String verifyAuth = '/api/auth/verify';

  // Onboarding
  static const String saveOnboarding = '/api/onboarding/save';

  // Score
  static const String calculateScore = '/api/score/calculate';

  // FIRE
  static const String firePlan = '/api/fire/plan';

  // Tax
  static const String taxCompare = '/api/tax/compare';

  // Chat
  static const String chatMessage = '/api/chat/message';

  // Dashboard
  static const String dashboard = '/api/user/dashboard';

  // Demo
  static const String demoEmail = 'demo@finiq.app';
  static const String demoPassword = 'FinIQ@Demo2026';

  // User profile
  static const String updateProfile = '/api/user/profile';

  // SharedPreferences keys
  static const String keyLanguage = 'app_language';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyUserProfile = 'user_profile';
}
