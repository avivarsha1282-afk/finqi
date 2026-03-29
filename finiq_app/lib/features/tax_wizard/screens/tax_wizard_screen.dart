import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/mock_data_service.dart';
import '../../language/providers/language_provider.dart';

class TaxWizardScreen extends ConsumerStatefulWidget {
  const TaxWizardScreen({super.key});
  @override ConsumerState<TaxWizardScreen> createState() => _TaxWizardScreenState();
}

class _TaxWizardScreenState extends ConsumerState<TaxWizardScreen> {
  double _income = 5000000;
  final _incomeCtrl = TextEditingController(text: '5000000');

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final report = MockDataService.getTaxReport(annualIncome: _income);

    final oldTax = report.oldRegime.taxPayable;
    final newTax = report.newRegime.taxPayable;
    final saving = (oldTax - newTax).abs();
    final isOldBetter = report.isOldRegimeBetter;
    final maxTax = oldTax > newTax ? oldTax : newTax;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'टैक्स तुलना' : 'Tax Wizard', style: AppTextStyles.subheading),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () {
              Share.share('💰 My Tax Comparison (FinIQ)\n'
                  'Income: ${CurrencyFormatter.compact(_income)}\n'
                  'Old Regime: ${CurrencyFormatter.compact(oldTax)}\n'
                  'New Regime: ${CurrencyFormatter.compact(newTax)}\n'
                  'Recommended: ${isOldBetter ? "Old" : "New"} Regime\n\n'
                  'Compare your tax with FinIQ! 📊');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Income Input ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ANNUAL GROSS INCOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _incomeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600, fontSize: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal),
                        onPressed: () {
                          final val = double.tryParse(_incomeCtrl.text);
                          if (val != null && val > 0) {
                            setState(() => _income = val);
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onFieldSubmitted: (v) {
                      final val = double.tryParse(v);
                      if (val != null && val > 0) setState(() => _income = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [500000.0, 800000.0, 1200000.0, 2500000.0, 5000000.0, 10000000.0].map((v) {
                      final selected = _income == v;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _income = v);
                          _incomeCtrl.text = v.toInt().toString();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryTeal.withOpacity(0.2) : const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: selected ? AppColors.primaryTeal : Colors.transparent),
                          ),
                          child: Text(CurrencyFormatter.compact(v), style: TextStyle(fontSize: 11, color: selected ? AppColors.primaryTeal : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── Regime Comparison ──────────────────────────────
            Row(
              children: [
                Expanded(child: _regimeCard(report.oldRegime, maxTax, isOldBetter)),
                const SizedBox(width: 12),
                Expanded(child: _regimeCard(report.newRegime, maxTax, !isOldBetter)),
              ],
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 20),

            // ── Savings Banner ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryTeal.withOpacity(0.12), AppColors.cardColor],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('YOU CAN SAVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(CurrencyFormatter.format(saving),
                      style: AppTextStyles.financialLarge.copyWith(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('by choosing ${isOldBetter ? "Old" : "New"} Regime',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // ── Missed Deductions ──────────────────────────────
            if (report.channels.isNotEmpty) ...[
              const Text('DEDUCTION OPPORTUNITIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...report.channels.asMap().entries.map((entry) {
                final ch = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_channelIcon(ch.icon), color: AppColors.warningAmber, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ch.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(ch.subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyFormatter.compact(ch.amount),
                              style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                          Text(ch.status, style: TextStyle(fontSize: 9, color: ch.status == 'NOT UTILIZED' ? AppColors.dangerRed : AppColors.warningAmber)),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 300 + entry.key * 100)).fadeIn();
              }),
            ],

            // ── Artha Verdict ──────────────────────────────────
            if (report.arthaVerdict.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      constraints: const BoxConstraints(minHeight: 80),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(radius: 12, backgroundColor: AppColors.primaryTeal,
                                child: const Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
                              const SizedBox(width: 8),
                              const Text('ARTHA VERDICT', style: TextStyle(color: AppColors.primaryTeal, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            ]),
                            const SizedBox(height: 10),
                            Text(report.arthaVerdict, style: AppTextStyles.arthaQuote),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Disclaimer ─────────────────────────────────────
            const SizedBox(height: 24),
            const Text(
              'Tax calculations are educational estimates based on FY 2025-26 slabs. Cess @ 4% included. '
              'Surcharge not applied. For actual tax filing, consult a CA. This is not tax advice.',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.5),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _regimeCard(dynamic regime, double maxTax, bool recommended) {
    final pct = maxTax > 0 ? regime.taxPayable / maxTax : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? AppColors.primaryTeal.withOpacity(0.08) : AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recommended ? AppColors.primaryTeal.withOpacity(0.4) : AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(regime.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('BEST', style: TextStyle(fontSize: 8, color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(CurrencyFormatter.compact(regime.taxPayable),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: recommended ? AppColors.primaryTeal : Colors.white, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text('${regime.effectiveRate.toStringAsFixed(1)}% effective',
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF1F2937),
              color: recommended ? AppColors.primaryTeal : AppColors.textTertiary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(String icon) {
    switch (icon) {
      case 'account_balance': return Icons.account_balance_rounded;
      case 'health_and_safety': return Icons.health_and_safety_rounded;
      case 'savings': return Icons.savings_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }
}
