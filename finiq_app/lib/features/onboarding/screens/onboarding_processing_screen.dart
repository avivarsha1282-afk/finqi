import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/user_data_service.dart';
import '../../../services/user_prefs_service.dart';

class OnboardingProcessingScreen extends StatefulWidget {
  const OnboardingProcessingScreen({super.key});
  @override State<OnboardingProcessingScreen> createState() => _OnboardingProcessingScreenState();
}

class _OnboardingProcessingScreenState extends State<OnboardingProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  int _messageIndex = 0;
  Timer? _messageTimer;

  static const _messages = [
    'Saving your financial profile...',
    'Analysing your income patterns...',
    'Calculating tax optimisation...',
    'Building your FIRE roadmap...',
    'Preparing your health score...',
    'Your plan is ready! ✨',
  ];

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // Cycle messages
    _messageTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_messageIndex < _messages.length - 1) {
        setState(() => _messageIndex++);
      } else {
        timer.cancel();
      }
    });

    // Process data and navigate
    _processAndNavigate();
  }

  Future<void> _processAndNavigate() async {
    try {
      // Step 1: Read onboarding JSON and persist as individual UID-prefixed keys
      final raw = await UserPrefsService.getString('onboarding_data');
      if (raw != null) {
        final data = json.decode(raw) as Map<String, dynamic>;
        await UserDataService.persistOnboardingData(data);

        // Step 2: Try Gemini analysis, with local fallback
        try {
          await _generateGeminiPlan(data);
        } catch (_) {
          // Gemini failed — calculate locally
          await UserDataService.calculateAndSaveLocally(data);
        }
      }

      // Step 3: Mark onboarding complete (UID-prefixed)
      await UserPrefsService.setOnboardingComplete(true);

      // Step 4: Navigate (wait for animations to finish)
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/home');
    } catch (e) {
      // Even on error, navigate to home after marking complete
      await UserPrefsService.setOnboardingComplete(true);
      if (mounted) context.go('/home');
    }
  }

  Future<void> _generateGeminiPlan(Map<String, dynamic> profile) async {
    final prompt = '''
Analyze this Indian user's financial data and return a JSON object.
Return ONLY valid JSON, no markdown, no explanation.

USER DATA:
Monthly Income: ${profile['monthly_income'] ?? 0}
Monthly Expenses: ${profile['monthly_expense'] ?? 0}
Current Savings: ${profile['current_savings'] ?? 0}
Has Health Insurance: ${profile['has_health_insurance'] ?? false}
Has Term Insurance: ${profile['has_term_insurance'] ?? false}
Total Monthly EMI: ${profile['total_emi'] ?? 0}
Annual 80C Investment: ${profile['annual_80c'] ?? 0}
Annual 80D (Health premium): ${profile['annual_80d'] ?? 0}
Annual NPS: ${profile['annual_nps'] ?? 0}
Goal Amount: ${profile['goal_amount'] ?? 1000000}
Goal Years: ${profile['goal_years'] ?? 5}
Risk Appetite: ${profile['risk_appetite'] ?? 'Moderate'}
Name: ${profile['name'] ?? 'User'}

Return this JSON:
{
  "health_score": <integer 0-100>,
  "grade": <"A" or "B" or "C" or "D" or "F">,
  "artha_brief": "<2 sentence personalised insight using their actual numbers>",
  "priority_action_1": "<most urgent action with specific numbers>",
  "priority_action_2": "<second most urgent action>",
  "priority_action_3": "<third action>"
}
''';

    final response = await http.post(
      Uri.parse('${ApiConstants.geminiEndpoint}?key=${ApiConstants.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 500},
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final jsonText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      final cleanJson = jsonText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final plan = json.decode(cleanJson) as Map<String, dynamic>;

        if (plan.containsKey('health_score')) {
          await UserPrefsService.setInt('health_score', (plan['health_score'] as num).toInt());
        }
        if (plan.containsKey('grade')) {
          await UserPrefsService.setString('grade', plan['grade']);
        }
        if (plan.containsKey('artha_brief')) {
          await UserPrefsService.setString('artha_brief', plan['artha_brief']);
        }
        if (plan.containsKey('priority_action_1')) {
          await UserPrefsService.setString('priority_action_1', plan['priority_action_1']);
        }
        if (plan.containsKey('priority_action_2')) {
          await UserPrefsService.setString('priority_action_2', plan['priority_action_2']);
        }
        if (plan.containsKey('priority_action_3')) {
          await UserPrefsService.setString('priority_action_3', plan['priority_action_3']);
        }

        // Still calculate dimension scores locally (Gemini unreliable for these)
        await UserDataService.calculateAndSaveLocally(profile);
      } catch (_) {
        // JSON parse failed — use local calculation
        await UserDataService.calculateAndSaveLocally(profile);
      }
    } else {
      // Non-200 — use local calculation
      await UserDataService.calculateAndSaveLocally(profile);
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Artha avatar with ring
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) {
                        return Container(
                          width: 80 + (_ringCtrl.value * 40),
                          height: 80 + (_ringCtrl.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryTeal.withOpacity(1 - _ringCtrl.value),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('A', style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 40),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _messageIndex == _messages.length - 1 ? FontWeight.w700 : FontWeight.w400,
                    color: _messageIndex == _messages.length - 1 ? AppColors.primaryTeal : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
