import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../widgets/onboarding_shared.dart';

class OnboardingStep4Screen extends StatefulWidget {
  const OnboardingStep4Screen({super.key});
  @override State<OnboardingStep4Screen> createState() => _OnboardingStep4ScreenState();
}

class _OnboardingStep4ScreenState extends State<OnboardingStep4Screen> {
  bool _hasHealthIns = false;
  bool _hasTermIns = false;
  bool _hasVehicleIns = false;
  final _healthCoverCtrl = TextEditingController(text: '0');
  final _termCoverCtrl = TextEditingController(text: '0');
  final _homeLoanCtrl = TextEditingController(text: '0');
  final _carLoanCtrl = TextEditingController(text: '0');
  final _personalLoanCtrl = TextEditingController(text: '0');
  final _creditCardCtrl = TextEditingController(text: '0');
  final _eduLoanCtrl = TextEditingController(text: '0');
  double _monthlyIncome = 0;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    final raw = await UserPrefsService.getString('onboarding_data');
    if (raw != null) {
      final data = json.decode(raw) as Map<String, dynamic>;
      setState(() => _monthlyIncome = (data['monthly_income'] ?? 0).toDouble());
    }
  }

  @override
  void dispose() {
    for (final c in [_healthCoverCtrl, _termCoverCtrl, _homeLoanCtrl, _carLoanCtrl, _personalLoanCtrl, _creditCardCtrl, _eduLoanCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(TextEditingController c) => parseAmount(c.text);
  double get _totalEmi => _val(_homeLoanCtrl) + _val(_carLoanCtrl) + _val(_personalLoanCtrl) + _val(_eduLoanCtrl);
  double get _dtiRatio => _monthlyIncome > 0 ? (_totalEmi / _monthlyIncome * 100) : 0;

  Future<void> _next() async {
    final raw = (await UserPrefsService.getString('onboarding_data')) ?? '{}';
    final data = json.decode(raw) as Map<String, dynamic>;
    data['has_health_insurance'] = _hasHealthIns;
    data['health_cover'] = _hasHealthIns ? _val(_healthCoverCtrl) : 0;
    data['has_term_insurance'] = _hasTermIns;
    data['term_cover'] = _hasTermIns ? _val(_termCoverCtrl) : 0;
    data['has_vehicle_insurance'] = _hasVehicleIns;
    data['home_loan_emi'] = _val(_homeLoanCtrl);
    data['car_loan_emi'] = _val(_carLoanCtrl);
    data['personal_loan_emi'] = _val(_personalLoanCtrl);
    data['credit_card_outstanding'] = _val(_creditCardCtrl);
    data['education_loan_emi'] = _val(_eduLoanCtrl);
    data['total_emi'] = _totalEmi;
    await UserPrefsService.setString('onboarding_data', json.encode(data));
    if (mounted) context.go('/onboarding/step5');
  }

  @override
  Widget build(BuildContext context) {
    Color dtiColor = AppColors.primaryTeal;
    if (_dtiRatio > 50) dtiColor = AppColors.dangerRed;
    else if (_dtiRatio > 30) dtiColor = AppColors.warningAmber;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            onboardingHeader(context, 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Protection & obligations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Critical for your complete financial picture', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),

                    const Text('INSURANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _toggleRow('Health Insurance', _hasHealthIns, (v) => setState(() => _hasHealthIns = v)),
                    if (_hasHealthIns) ...[
                      const SizedBox(height: 8),
                      TextFormField(controller: _healthCoverCtrl, keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                        style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('Cover amount', prefix: '₹ ')),
                    ] else ...[
                      const SizedBox(height: 4),
                      const Text('⚠ We\'ll address this in your plan', style: TextStyle(fontSize: 12, color: AppColors.warningAmber)),
                    ],
                    const SizedBox(height: 16),

                    _toggleRow('Term Life Insurance', _hasTermIns, (v) => setState(() => _hasTermIns = v)),
                    if (_hasTermIns) ...[
                      const SizedBox(height: 8),
                      TextFormField(controller: _termCoverCtrl, keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                        style: const TextStyle(color: Colors.white),
                        decoration: onboardingInputDecoration('Sum assured', prefix: '₹ ')),
                    ],
                    const SizedBox(height: 16),

                    _toggleRow('Vehicle Insurance', _hasVehicleIns, (v) => setState(() => _hasVehicleIns = v)),

                    const SizedBox(height: 24),
                    const Text('DEBT / EMI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _emiField('Home Loan EMI', _homeLoanCtrl),
                    _emiField('Car Loan EMI', _carLoanCtrl),
                    _emiField('Personal Loan EMI', _personalLoanCtrl),
                    _emiField('Credit Card Outstanding', _creditCardCtrl),
                    _emiField('Education Loan EMI', _eduLoanCtrl),

                    if (_totalEmi > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dtiColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dtiColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(children: [
                              const Icon(Icons.credit_card_rounded, color: AppColors.textSecondary, size: 18),
                              const SizedBox(width: 8),
                              Text('Total monthly EMI: ₹${_totalEmi.toInt()}',
                                style: TextStyle(color: dtiColor, fontWeight: FontWeight.w600)),
                            ]),
                            if (_monthlyIncome > 0) ...[
                              const SizedBox(height: 8),
                              Text('${_dtiRatio.toStringAsFixed(0)}% of income goes to EMIs',
                                style: TextStyle(fontSize: 12, color: dtiColor)),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
              ),
            ),
            onboardingContinueButton(_next),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryTeal),
      ]),
    );
  }

  Widget _emiField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(controller: ctrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('0', prefix: '₹ '),
            onChanged: (_) => setState(() {})),
        ],
      ),
    );
  }
}
