import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/onboarding_shared.dart';

class OnboardingStep1Screen extends StatefulWidget {
  const OnboardingStep1Screen({super.key});

  @override
  State<OnboardingStep1Screen> createState() => _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends State<OnboardingStep1Screen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _occupation = 'Salaried Employee';
  bool _partTime = false;
  final _formKey = GlobalKey<FormState>();

  static const _occupations = [
    'Salaried Employee', 'Business Owner', 'Freelancer / Self-employed', 'Student', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = await UserPrefsService.getString('onboarding_data');
    final data = raw != null ? json.decode(raw) as Map<String, dynamic> : <String, dynamic>{};
    data['name'] = _nameCtrl.text.trim();
    data['age'] = int.tryParse(_ageCtrl.text.trim()) ?? 25;
    data['city'] = _cityCtrl.text.trim();
    data['occupation'] = _occupation;
    if (_occupation == 'Student') data['part_time'] = _partTime;
    await UserPrefsService.setString('onboarding_data', json.encode(data));
    if (mounted) context.go('/onboarding/step2');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            onboardingHeader(context, 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tell us about yourself',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('This helps Artha personalise your plan',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 32),
                      onboardingLabel('Full Name'),
                      TextFormField(controller: _nameCtrl, style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('Your full name'),
                        validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required'),
                      const SizedBox(height: 20),
                      onboardingLabel('Age'),
                      TextFormField(controller: _ageCtrl, keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('25'),
                        validator: (v) { final a = int.tryParse(v ?? ''); return (a != null && a >= 18 && a <= 70) ? null : 'Age must be 18-70'; }),
                      const SizedBox(height: 20),
                      onboardingLabel('City'),
                      TextFormField(controller: _cityCtrl, style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('Pune, Mumbai, Delhi...'),
                        validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required'),
                      const SizedBox(height: 20),
                      onboardingLabel('Occupation Type'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonFormField<String>(
                          value: _occupation, dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: _occupations.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                          onChanged: (v) => setState(() => _occupation = v ?? _occupation)),
                      ),
                      if (_occupation == 'Student') ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Expanded(child: Text('Working part-time?', style: TextStyle(color: Colors.white, fontSize: 15))),
                            Switch(value: _partTime, onChanged: (v) => setState(() => _partTime = v), activeColor: AppColors.primaryTeal),
                          ]),
                        ),
                      ],
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
