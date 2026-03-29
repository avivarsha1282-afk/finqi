import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/onboarding_shared.dart';

class OnboardingStep2Screen extends StatefulWidget {
  const OnboardingStep2Screen({super.key});
  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final _salaryCtrl = TextEditingController();
  final _ctcCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _hraCtrl = TextEditingController();
  String _occupation = 'Salaried Employee';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadOccupation();
  }

  Future<void> _loadOccupation() async {
    final raw = await UserPrefsService.getString('onboarding_data');
    if (raw != null) {
      final data = json.decode(raw) as Map<String, dynamic>;
      setState(() => _occupation = data['occupation'] ?? 'Salaried Employee');
    }
  }

  @override
  void dispose() {
    _salaryCtrl.dispose(); _ctcCtrl.dispose(); _expenseCtrl.dispose();
    _rentCtrl.dispose(); _hraCtrl.dispose();
    super.dispose();
  }

  double get _income => double.tryParse(_salaryCtrl.text) ?? 0;
  double get _expense => double.tryParse(_expenseCtrl.text) ?? 0;

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = (await UserPrefsService.getString('onboarding_data')) ?? '{}';
    final data = json.decode(raw) as Map<String, dynamic>;
    data['monthly_income'] = _income;
    data['annual_income'] = _income * 12;
    data['monthly_expense'] = _expense;
    data['monthly_rent'] = double.tryParse(_rentCtrl.text) ?? 0;
    data['hra_received'] = double.tryParse(_hraCtrl.text) ?? 0;
    data['annual_ctc'] = double.tryParse(_ctcCtrl.text) ?? 0;
    await UserPrefsService.setString('onboarding_data', json.encode(data));
    if (mounted) context.go('/onboarding/step3');
  }

  @override
  Widget build(BuildContext context) {
    final savings = _income - _expense;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            onboardingHeader(context, 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your money flow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Artha needs this to calculate your financial health', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 32),
                      onboardingLabel('Monthly Take-Home Salary'),
                      TextFormField(controller: _salaryCtrl, keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('50,000', prefix: '₹ '),
                        onChanged: (_) => setState(() {}),
                        validator: (v) { final val = double.tryParse(v ?? ''); return (val != null && val >= 5000) ? null : 'Min ₹5,000'; }),
                      const SizedBox(height: 20),
                      if (_occupation == 'Salaried Employee') ...[
                        onboardingLabel('Annual CTC (optional)'),
                        TextFormField(controller: _ctcCtrl, keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: onboardingInputDecoration('6,00,000', prefix: '₹ ')),
                        const SizedBox(height: 20),
                      ],
                      onboardingLabel('Monthly Total Expenses'),
                      TextFormField(controller: _expenseCtrl, keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('25,000', prefix: '₹ '),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (double.tryParse(v ?? '') != null) ? null : 'Required'),
                      const SizedBox(height: 20),
                      onboardingLabel('Monthly House Rent Paid'),
                      TextFormField(controller: _rentCtrl, keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('0 if living with family', prefix: '₹ ')),
                      const SizedBox(height: 20),
                      if (_occupation == 'Salaried Employee') ...[
                        onboardingLabel('HRA Received Monthly'),
                        TextFormField(controller: _hraCtrl, keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: onboardingInputDecoration('0 if not applicable', prefix: '₹ ')),
                        const SizedBox(height: 20),
                      ],
                      if (_income > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.savings_rounded, color: AppColors.primaryTeal, size: 20),
                            const SizedBox(width: 12),
                            Text('You save ₹${savings.toInt()} per month',
                              style: TextStyle(color: savings >= 0 ? AppColors.primaryTeal : AppColors.dangerRed, fontWeight: FontWeight.w600)),
                          ]),
                        ).animate().fadeIn(),
                      const SizedBox(height: 40),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
                ),
              ),
            ),
            onboardingContinueButton(_next),
          ],
        ),
      ),
    );
  }
}
