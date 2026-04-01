import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../widgets/onboarding_shared.dart';

class OnboardingStep5Screen extends StatefulWidget {
  const OnboardingStep5Screen({super.key});
  @override State<OnboardingStep5Screen> createState() => _OnboardingStep5ScreenState();
}

class _OnboardingStep5ScreenState extends State<OnboardingStep5Screen> {
  String? _goalType;
  final _goalNameCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  final _goalSavingsCtrl = TextEditingController(text: '0');
  double _goalYears = 7;
  String _riskAppetite = 'Moderate';
  final _formKey = GlobalKey<FormState>();

  static const _goals = [
    {'icon': '🏠', 'label': 'Buy a Home'},
    {'icon': '🎓', 'label': 'Education'},
    {'icon': '✈️', 'label': 'Travel'},
    {'icon': '💍', 'label': 'Marriage'},
    {'icon': '🏦', 'label': 'Build Wealth'},
    {'icon': '🔥', 'label': 'Early Retirement'},
    {'icon': '🚗', 'label': 'Buy a Vehicle'},
    {'icon': '🏥', 'label': 'Emergency Fund'},
  ];

  @override
  void dispose() {
    _goalNameCtrl.dispose(); _goalAmountCtrl.dispose(); _goalSavingsCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_goalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal type'), backgroundColor: AppColors.dangerRed));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final raw = (await UserPrefsService.getString('onboarding_data')) ?? '{}';
    final data = json.decode(raw) as Map<String, dynamic>;
    data['goal_type'] = _goalType;
    data['goal_name'] = _goalNameCtrl.text.trim();
    data['goal_amount'] = parseAmount(_goalAmountCtrl.text);
    data['goal_years'] = _goalYears.toInt();
    data['goal_savings'] = parseAmount(_goalSavingsCtrl.text);
    data['risk_appetite'] = _riskAppetite;
    await UserPrefsService.setString('onboarding_data', json.encode(data));
    if (mounted) context.go('/onboarding/processing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            onboardingHeader(context, 5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What are you working toward?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Artha will build your personalised roadmap', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),

                      const Text('PRIMARY GOAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _goals.length,
                          itemBuilder: (_, i) {
                            final g = _goals[i];
                            final selected = _goalType == g['label'];
                            return GestureDetector(
                              onTap: () => setState(() => _goalType = g['label']),
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primaryTeal.withOpacity(0.15) : const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: selected ? AppColors.primaryTeal : const Color(0xFF1F2937)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(g['icon']!, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 6),
                                    Text(g['label']!, textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11, color: selected ? AppColors.primaryTeal : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      if (_goalType != null) ...[
                        const SizedBox(height: 24),
                        onboardingLabel('Goal Name'),
                        TextFormField(controller: _goalNameCtrl, style: const TextStyle(color: Colors.white),
                          decoration: onboardingInputDecoration('e.g. Pune Home'),
                          validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required'),
                        const SizedBox(height: 16),
                        onboardingLabel('Target Amount'),
                        TextFormField(controller: _goalAmountCtrl, keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                          style: const TextStyle(color: Colors.white),
                          decoration: onboardingInputDecoration('1,52,00,000', prefix: '₹ '),
                          validator: (v) => (parseAmount(v) > 0) ? null : 'Required'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            onboardingLabel('Target Timeline'),
                            const Spacer(),
                            Text('${_goalYears.toInt()} years', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Slider(value: _goalYears, min: 1, max: 30, divisions: 29,
                          activeColor: AppColors.primaryTeal, inactiveColor: const Color(0xFF1F2937),
                          onChanged: (v) => setState(() => _goalYears = v)),
                        const SizedBox(height: 16),
                        onboardingLabel('Current savings toward this goal'),
                        TextFormField(controller: _goalSavingsCtrl, keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                          style: const TextStyle(color: Colors.white),
                          decoration: onboardingInputDecoration('0', prefix: '₹ ')),
                      ],

                      const SizedBox(height: 32),
                      const Text('RISK APPETITE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _riskCard('Conservative', '🛡️', 'Safety over returns'),
                          const SizedBox(width: 8),
                          _riskCard('Moderate', '⚖️', 'Balanced growth'),
                          const SizedBox(width: 8),
                          _riskCard('Aggressive', '🚀', 'High returns ok'),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
                ),
              ),
            ),
            onboardingContinueButton(_finish, label: 'Calculate My Financial Plan'),
          ],
        ),
      ),
    );
  }

  Widget _riskCard(String label, String emoji, String desc) {
    final selected = _riskAppetite == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _riskAppetite = label),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTeal.withOpacity(0.15) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primaryTeal : const Color(0xFF1F2937)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, color: selected ? AppColors.primaryTeal : Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}
