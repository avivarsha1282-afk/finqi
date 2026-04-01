import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../widgets/onboarding_shared.dart';

class OnboardingStep3Screen extends StatefulWidget {
  const OnboardingStep3Screen({super.key});
  @override State<OnboardingStep3Screen> createState() => _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState extends State<OnboardingStep3Screen> {
  final _savingsCtrl = TextEditingController(text: '0');
  final _fdCtrl = TextEditingController(text: '0');
  final _mfCtrl = TextEditingController(text: '0');
  final _stocksCtrl = TextEditingController(text: '0');
  final _ppfCtrl = TextEditingController(text: '0');
  final _npsCtrl = TextEditingController(text: '0');
  final _goldCtrl = TextEditingController(text: '0');
  final _otherCtrl = TextEditingController(text: '0');
  final _sec80cCtrl = TextEditingController(text: '0');
  final _sec80dCtrl = TextEditingController(text: '0');
  final _npsAnnualCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    for (final c in [_savingsCtrl, _fdCtrl, _mfCtrl, _stocksCtrl, _ppfCtrl, _npsCtrl, _goldCtrl, _otherCtrl, _sec80cCtrl, _sec80dCtrl, _npsAnnualCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(TextEditingController c) => parseAmount(c.text);

  double get _totalSavings => _val(_savingsCtrl) + _val(_fdCtrl) + _val(_mfCtrl) + _val(_stocksCtrl) +
      _val(_ppfCtrl) + _val(_npsCtrl) + _val(_goldCtrl) + _val(_otherCtrl);

  Future<void> _next() async {
    final raw = (await UserPrefsService.getString('onboarding_data')) ?? '{}';
    final data = json.decode(raw) as Map<String, dynamic>;
    data['current_savings'] = _totalSavings;
    data['savings_account'] = _val(_savingsCtrl);
    data['fixed_deposits'] = _val(_fdCtrl);
    data['mutual_funds'] = _val(_mfCtrl);
    data['stocks'] = _val(_stocksCtrl);
    data['ppf'] = _val(_ppfCtrl);
    data['nps'] = _val(_npsCtrl);
    data['gold'] = _val(_goldCtrl);
    data['other_investments'] = _val(_otherCtrl);
    data['annual_80c'] = _val(_sec80cCtrl);
    data['annual_80d'] = _val(_sec80dCtrl);
    data['annual_nps'] = _val(_npsAnnualCtrl);
    await UserPrefsService.setString('onboarding_data', json.encode(data));
    if (mounted) context.go('/onboarding/step4');
  }

  Widget _field(String label, TextEditingController ctrl, {bool optional = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (optional) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Optional', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  style: const TextStyle(color: Colors.white),
                  decoration: onboardingInputDecoration('0', prefix: '₹ '),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            onboardingHeader(context, 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What do you already have?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Even ₹0 is a valid answer — no judgment here', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),

                    const Text('CURRENT SAVINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _field('Savings Account Balance', _savingsCtrl, optional: false),
                    _field('Fixed Deposits', _fdCtrl),

                    const SizedBox(height: 16),
                    const Text('INVESTMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _field('Mutual Funds', _mfCtrl),
                    _field('Stocks / Equity', _stocksCtrl),
                    _field('PPF Balance', _ppfCtrl),
                    _field('NPS Balance', _npsCtrl),
                    _field('Gold (physical or digital)', _goldCtrl),
                    _field('Other investments', _otherCtrl),

                    const SizedBox(height: 16),
                    const Text('80C INVESTMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    onboardingLabel('Annual 80C investment (ELSS, PPF, LIC combined)'),
                    TextFormField(controller: _sec80cCtrl, keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                      style: const TextStyle(color: Colors.white),
                      decoration: onboardingInputDecoration('0', prefix: '₹ ')),
                    const SizedBox(height: 4),
                    const Text('Max: ₹1,50,000', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    const SizedBox(height: 16),
                    onboardingLabel('Health Insurance Premium (80D)'),
                    TextFormField(controller: _sec80dCtrl, keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                      style: const TextStyle(color: Colors.white),
                      decoration: onboardingInputDecoration('0', prefix: '₹ ')),
                    const SizedBox(height: 16),
                    onboardingLabel('Annual NPS Contribution'),
                    TextFormField(controller: _npsAnnualCtrl, keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                      style: const TextStyle(color: Colors.white),
                      decoration: onboardingInputDecoration('0', prefix: '₹ ')),

                    const SizedBox(height: 24),
                    if (_totalSavings > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryTeal, size: 20),
                          const SizedBox(width: 12),
                          Text('Total: ₹${_totalSavings.toInt()}',
                            style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                        ]),
                      ),
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
}
