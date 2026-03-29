import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/api_service.dart';
import '../../language/providers/language_provider.dart';
import '../../../core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final List<ChatMessage> messages;
  final Map<String, dynamic> collectedData;
  final int currentQuestion;
  final bool isComplete;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.messages = const [],
    this.collectedData = const {},
    this.currentQuestion = 0,
    this.isComplete = false,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    List<ChatMessage>? messages,
    Map<String, dynamic>? collectedData,
    int? currentQuestion,
    bool? isComplete,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      messages: messages ?? this.messages,
      collectedData: collectedData ?? this.collectedData,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      isComplete: isComplete ?? this.isComplete,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState());

  String get _lang => _ref.read(languageProvider);

  static const List<String> _questions = [
    'monthly_salary',
    'monthly_expenses',
    'current_savings',
    'existing_investments',
    'emis',
    'health_insurance',
    'life_insurance',
    'section_80c',
    'house_rent',
    'nps_contribution',
    'financial_goal',
    'target_timeline',
  ];

  Future<void> startOnboarding() async {
    state = state.copyWith(isLoading: true, currentQuestion: 1);

    final greeting = _lang == 'hi'
        ? '👋 नमस्ते! मैं अर्था हूं, आपका व्यक्तिगत वित्त मार्गदर्शक। आपकी वित्तीय रणनीति बनाने के लिए मुझे आपकी स्थिति को समझना होगा। आपकी मासिक टेक-होम सैलरी क्या है?'
        : '👋 Hi! I\'m Artha, your personal finance mentor. To build your financial strategy, I need to understand your situation. What\'s your monthly take-home salary?';

    final firstMessage = ChatMessage.artha(greeting);
    state = state.copyWith(
      messages: [firstMessage],
      isLoading: false,
    );
  }

  static const List<String> _nextQuestions = [
    '💰 What are your monthly expenses (rent, food, bills, etc.)?',
    '🏦 How much do you currently have in savings or bank account?',
    '📈 Do you have any existing investments? (MF, stocks, FDs, PPF, etc.)',
    '💳 Do you have any EMIs or loans? If yes, what is the total monthly amount?',
    '🏥 Do you have health insurance? (Yes / No)',
    '🛡️ Do you have life insurance? If yes, what is the annual premium?',
    '📋 How much do you invest under Section 80C? (PPF, ELSS, LIC, etc.)',
    '🏠 Do you pay house rent? If yes, how much per month?',
    '🧓 Do you contribute to NPS (National Pension System)? If yes, how much annually?',
    '🎯 What is your primary financial goal? (e.g. early retirement, buying home, child education)',
    '📅 In how many years do you want to achieve this goal?',
    '✅ Thank you! I have everything I need to build your personalized FinIQ profile. Setting up your dashboard now...',
  ];

  Future<void> sendAnswer(String answer) async {
    // Add user message
    final userMsg = ChatMessage.user(answer);

    // Update collected data
    final key = state.currentQuestion <= _questions.length
        ? _questions[state.currentQuestion - 1]
        : 'extra_${state.currentQuestion}';

    final updatedData = Map<String, dynamic>.from(state.collectedData);
    updatedData[key] = answer;

    final newQ = state.currentQuestion + 1;
    final isNowComplete = newQ > 12;

    // Get next question locally — no API call needed
    String nextText;
    if (!isNowComplete) {
      nextText = _nextQuestions[state.currentQuestion - 1];
    } else {
      nextText = _nextQuestions.last;
    }

    final arthsResponse = ChatMessage.artha(nextText);

    state = state.copyWith(
      messages: [...state.messages, userMsg, arthsResponse],
      collectedData: updatedData,
      currentQuestion: newQ,
      isComplete: isNowComplete,
      isLoading: isNowComplete,
    );

    if (isNowComplete) {
      await _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      await ApiService.instance.saveOnboarding(state.collectedData);
    } catch (_) {
      // Silently continue — data can be synced later
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ApiConstants.keyOnboardingComplete, true);
    state = state.copyWith(isComplete: true, isLoading: false);
  }

  void reset() => state = const OnboardingState();
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});
