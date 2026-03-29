class ApiConstants {
  ApiConstants._();

  /// Demo mode ON — all data from UserDataService, no Flask backend needed.
  static const bool demoMode = true;

  // Gemini API (direct from Flutter — no Flask backend)
  static const String geminiApiKey = 'AIzaSyBLMkfl11n2o0-1hZIZx94To-q_W_B_vKY';
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // SharedPreferences keys
  static const String keyLanguage = 'app_language';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyUserProfile = 'user_profile';
  static const String keyOnboardingData = 'onboarding_data';

  // Demo account (for Firebase email login fallback)
  static const String demoEmail = 'demo@finiq.app';
  static const String demoPassword = 'FinIQ@Demo2026';
}
