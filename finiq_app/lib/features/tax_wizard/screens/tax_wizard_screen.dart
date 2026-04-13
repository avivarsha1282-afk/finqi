import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/tax_report_model.dart';
import '../../../services/api_service.dart';
import '../../../services/user_data_service.dart';
import '../../../l10n/t.dart';

class TaxWizardScreen extends ConsumerStatefulWidget {
  const TaxWizardScreen({super.key});
  @override ConsumerState<TaxWizardScreen> createState() => _TaxWizardScreenState();
}

class _TaxWizardScreenState extends ConsumerState<TaxWizardScreen> {
  double _income = 0;
  final _incomeCtrl = TextEditingController();
  TaxReportModel? _report;
  bool _isLoading = true;
  bool _showDeductions = false;

  // Deduction controllers
  final _ctrl80c = TextEditingController(text: '0');
  final _ctrl80d = TextEditingController(text: '0');
  final _ctrlNps = TextEditingController(text: '0');
  final _ctrlHra = TextEditingController(text: '0');
  final _ctrlHome = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profile = await UserDataService.getUserProfile();
    final realIncome = profile['annual_income']?.toDouble() ?? 5000000.0;
    _incomeCtrl.text = _formatIndian(realIncome.toInt());
    _setIncome(realIncome);
  }

  String _formatIndian(int value) {
    if (value <= 0) return '0';
    String s = value.toString();
    if (s.length <= 3) return s;
    String result = s.substring(s.length - 3);
    s = s.substring(0, s.length - 3);
    while (s.length > 2) {
      result = '${s.substring(s.length - 2)},$result';
      s = s.substring(0, s.length - 2);
    }
    if (s.isNotEmpty) result = '$s,$result';
    return result;
  }

  void _setIncome(double v) {
    setState(() {
      _income = v;
      _isLoading = true;
    });
    _fetchReport(v);
  }

  Future<void> _fetchReport(double inc) async {
    try {
      final report = await ApiService.instance.compareTax(
        annualIncome: inc,
        investment80c: _showDeductions ? double.tryParse(_ctrl80c.text.replaceAll(',', '')) ?? 0 : null,
        premium80d: _showDeductions ? double.tryParse(_ctrl80d.text.replaceAll(',', '')) ?? 0 : null,
        npsContribution: _showDeductions ? double.tryParse(_ctrlNps.text.replaceAll(',', '')) ?? 0 : null,
        hra: _showDeductions ? double.tryParse(_ctrlHra.text.replaceAll(',', '')) ?? 0 : null,
        homeLoanInterest: _showDeductions ? double.tryParse(_ctrlHome.text.replaceAll(',', '')) ?? 0 : null,
      );
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _ctrl80c.dispose();
    _ctrl80d.dispose();
    _ctrlNps.dispose();
    _ctrlHra.dispose();
    _ctrlHome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(t(ref, 'tax_wizard'), style: AppTextStyles.subheading),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryTeal),
            tooltip: 'Refresh',
            onPressed: () {
              _setIncome(_income);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing tax comparison...'),
                    backgroundColor: AppColors.primaryTeal, duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () {
              if (_report == null) return;
              Share.share('💰 My Tax Comparison (FinIQ)\n'
                  'Income: ${CurrencyFormatter.compact(_income)}\n'
                  'Old Regime: ${CurrencyFormatter.compact(_report!.oldRegime.taxPayable)}\n'
                  'New Regime: ${CurrencyFormatter.compact(_report!.newRegime.taxPayable)}\n'
                  'Recommended: ${_report!.isOldRegimeBetter ? "Old" : "New"} Regime\n\n'
                  'Compare your tax with FinIQ! 📊');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 100, // Clear FAB
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Income Input ───────────────────────────────────
            _buildIncomeInput(),
            const SizedBox(height: 24),

            if (_isLoading || _report == null)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
            else ...[
              // ── Regime Comparison ──────────────────────────────
              Row(
                children: [
                  Expanded(child: _regimeCard(_report!.oldRegime,
                      _report!.oldRegime.taxPayable > _report!.newRegime.taxPayable
                          ? _report!.oldRegime.taxPayable : _report!.newRegime.taxPayable,
                      _report!.isOldRegimeBetter)),
                  const SizedBox(width: 12),
                  Expanded(child: _regimeCard(_report!.newRegime,
                      _report!.oldRegime.taxPayable > _report!.newRegime.taxPayable
                          ? _report!.oldRegime.taxPayable : _report!.newRegime.taxPayable,
                      !_report!.isOldRegimeBetter)),
                ],
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 16),

              // ── Savings Banner ─────────────────────────────────
              _buildSavingsBanner(),

              // ── What-if maximise deductions ────────────────────
              if (!_report!.isOldRegimeBetter && _report!.maxDeductionProjection != null
                  && _report!.maxDeductionProjection!.additionalSavings > 0)
                _buildMaxDeductionHint(),

              const SizedBox(height: 24),

              // ── Deduction Input Mode ───────────────────────────
              _buildDeductionToggle(),

              if (_showDeductions) ...[
                const SizedBox(height: 16),
                _buildDeductionInputs(),
              ],

              const SizedBox(height: 24),

              // ── Deduction Opportunities ─────────────────────────
              if (_report!.channels.isNotEmpty) ...[
                const Text('DEDUCTION OPPORTUNITIES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ..._report!.channels.asMap().entries.map((entry) =>
                    _buildDeductionRow(entry.value)
                        .animate(delay: Duration(milliseconds: 300 + entry.key * 100)).fadeIn()
                ),
              ],

              // ── Artha Verdict ──────────────────────────────────
              if (_report!.arthaVerdict.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildArthaVerdict(),
              ],
            ],

            // ── Disclaimer ─────────────────────────────────────
            const SizedBox(height: 24),
            const Text(
              'Tax calculations are educational estimates based on FY 2025-26 slabs. Cess @ 4% included. '
              'Surcharge not applied. For actual tax filing, consult a CA.',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INCOME INPUT with Indian formatting
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIncomeInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ANNUAL GROSS INCOME',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_IndianNumberFormatter()],
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600, fontSize: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal),
                onPressed: () {
                  final val = double.tryParse(_incomeCtrl.text.replaceAll(',', ''));
                  if (val != null && val > 0) {
                    FocusScope.of(context).unfocus();
                    _setIncome(val);
                  }
                },
              ),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onFieldSubmitted: (v) {
              final val = double.tryParse(v.replaceAll(',', ''));
              if (val != null && val > 0) _setIncome(val);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [500000.0, 800000.0, 1200000.0, 2500000.0, 5000000.0, 10000000.0].map((v) {
              final selected = _income == v;
              return GestureDetector(
                onTap: () {
                  _incomeCtrl.text = _formatIndian(v.toInt());
                  _setIncome(v);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryTeal.withValues(alpha: 0.2) : const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? AppColors.primaryTeal : Colors.transparent),
                  ),
                  child: Text(CurrencyFormatter.compact(v),
                      style: TextStyle(fontSize: 11,
                          color: selected ? AppColors.primaryTeal : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVINGS BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSavingsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryTeal.withValues(alpha: 0.12), AppColors.cardColor],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('YOU CAN SAVE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(
              (_report!.oldRegime.taxPayable - _report!.newRegime.taxPayable).abs()),
              style: AppTextStyles.financialLarge.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text('by choosing ${_report!.isOldRegimeBetter ? "Old" : "New"} Regime',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WHAT-IF MAX DEDUCTIONS HINT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMaxDeductionHint() {
    final proj = _report!.maxDeductionProjection!;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.warningAmber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                const TextSpan(text: 'If you maximise 80C+80D+NPS: ',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                TextSpan(
                    text: 'Save ₹${CurrencyFormatter.compact(proj.additionalSavings)} more',
                    style: TextStyle(color: AppColors.warningAmber,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showDeductions = true),
            child: const Text('Calculate →',
                style: TextStyle(color: AppColors.primaryTeal,
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEDUCTION TOGGLE + INPUTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeductionToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showDeductions = !_showDeductions),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_outlined, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 10),
            const Text('Add my actual deductions',
                style: TextStyle(fontSize: 14, color: Colors.white)),
            const Spacer(),
            Icon(_showDeductions ? Icons.expand_less : Icons.expand_more,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          _deductionField('Section 80C (ELSS, PPF, LIC)', _ctrl80c, 150000),
          const SizedBox(height: 12),
          _deductionField('Section 80D (Health Insurance)', _ctrl80d, 25000),
          const SizedBox(height: 12),
          _deductionField('NPS 80CCD(1B)', _ctrlNps, 50000),
          const SizedBox(height: 12),
          _deductionField('HRA Claimed', _ctrlHra, null),
          const SizedBox(height: 12),
          _deductionField('Home Loan Interest', _ctrlHome, 200000),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _setIncome(_income),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Recalculate', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _deductionField(String label, TextEditingController ctrl, int? maxLimit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white70))),
            if (maxLimit != null)
              Text('Max: ₹${_formatIndian(maxLimit)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: AppColors.primaryTeal, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEDUCTION ROW — Teal "SAVE ₹X" instead of red "NOT UTILIZED"
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeductionRow(TaxChannel ch) {
    Color statusColor;
    String statusText;

    switch (ch.deductionStatus) {
      case 'MAXIMISED':
        statusColor = AppColors.primaryTeal;
        statusText = 'MAXIMISED ✓';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'PARTIAL':
        statusColor = AppColors.warningAmber;
        statusText = '₹${CurrencyFormatter.compact(ch.remaining)} left';
        statusIcon = Icons.pending_outlined;
        break;
      default: // NOT_UTILISED
        statusColor = AppColors.primaryTeal;
        statusText = 'SAVE ${CurrencyFormatter.compact(ch.taxSavingIfMaximised)}';
        statusIcon = Icons.add_circle_outline;
    }

    return GestureDetector(
      onTap: () => _showDeductionDetail(ch),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // Section icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_channelIcon(ch.icon), color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Section info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.name,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                Text(ch.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white38)),
                const SizedBox(height: 4),
                Text(
                  ch.deductionStatus == 'NOT_UTILISED'
                      ? 'Invest ${CurrencyFormatter.compact(ch.monthlyToMaximise)}/mo → save ${CurrencyFormatter.compact(ch.taxSavingIfMaximised)}/yr'
                      : 'Invested: ${CurrencyFormatter.compact(ch.utilised)} of ${CurrencyFormatter.compact(ch.maximum)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            )),

            // Status badge + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEDUCTION DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showDeductionDetail(TaxChannel ch) {
    final items = _getQualifyingItems(ch.sectionCode);
    final progress = ch.maximum > 0 ? ch.utilised / ch.maximum : 0.0;
    final marginalPct = ((_report?.marginalRate ?? 0.3) * 100).round();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            Text(ch.name,
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            Text(ch.subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 20),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Limit used',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    Text('${CurrencyFormatter.compact(ch.utilised)} / ${CurrencyFormatter.compact(ch.maximum)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1F2937),
                    color: AppColors.primaryTeal,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Key numbers grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _gridItem('Annual Limit', CurrencyFormatter.compact(ch.maximum)),
                _gridItem('You Use', CurrencyFormatter.compact(ch.utilised)),
                _gridItem('Remaining', CurrencyFormatter.compact(ch.remaining)),
                _gridItem('Tax Saved', '${CurrencyFormatter.compact(ch.taxSavingIfMaximised)}/yr'),
                _gridItem('Monthly SIP', '${CurrencyFormatter.compact(ch.monthlyToMaximise)}/mo'),
                _gridItem('Tax Bracket', '$marginalPct%'),
              ],
            ),
            const SizedBox(height: 20),

            // Qualifying items
            const Text('What qualifies:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.white70)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 5, height: 5,
                      margin: const EdgeInsets.only(top: 7, right: 8),
                      decoration: const BoxDecoration(
                          color: AppColors.primaryTeal, shape: BoxShape.circle)),
                  Expanded(child: Text(item,
                      style: const TextStyle(fontSize: 13,
                          color: Colors.white60, height: 1.4))),
                ],
              ),
            )),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _gridItem(String label, String value) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  List<String> _getQualifyingItems(String section) {
    switch (section) {
      case '80C': return [
        'ELSS Mutual Funds (3-year lock-in)',
        'PPF (Public Provident Fund)',
        'EPF Employee Contribution',
        'Tax-Saver Fixed Deposits (5-year)',
        'NSC (National Savings Certificate)',
        'LIC Premium',
        'Home Loan Principal',
        'Children\'s Tuition Fees',
      ];
      case '80D': return [
        'Health insurance for self/spouse/children',
        'Health insurance for parents (extra ₹25K)',
        'Preventive health check-up (₹5K sub-limit)',
      ];
      case '80CCD': return [
        'NPS Tier 1 account contribution',
        'Over and above the ₹1.5L 80C limit',
        'Available for both employee and employer NPS',
      ];
      default: return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTHA VERDICT — Full card with "Ask Artha" button
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildArthaVerdict() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.12),
            AppColors.primaryTeal.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(radius: 14, backgroundColor: AppColors.primaryTeal,
                child: Text('A', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: Colors.white))),
            const SizedBox(width: 10),
            const Text("Artha's Tax Verdict",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal)),
          ]),
          const SizedBox(height: 12),
          Text(_report!.arthaVerdict,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Navigate to Artha chat with tax context
              Navigator.of(context).pushNamed('/artha');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.30)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Ask Artha for personalised advice →',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13,
                      color: AppColors.primaryTeal, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REGIME CARD (existing, cleaned up)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _regimeCard(dynamic regime, double maxTax, bool recommended) {
    final pct = maxTax > 0 ? regime.taxPayable / maxTax : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? AppColors.primaryTeal.withValues(alpha: 0.08) : AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recommended
            ? AppColors.primaryTeal.withValues(alpha: 0.4) : AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(regime.label,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 13))),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('BEST',
                    style: TextStyle(fontSize: 8, color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 12),
          Text(CurrencyFormatter.compact(regime.taxPayable),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: recommended ? AppColors.primaryTeal : Colors.white,
                  fontFamily: 'monospace')),
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

/// Indian number formatter for text fields
/// Formats: 30,00,000 (Indian style)
class _IndianNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue;
    final number = int.tryParse(raw);
    if (number == null) return oldValue;

    String s = number.toString();
    if (s.length <= 3) {
      return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
    }

    String result = s.substring(s.length - 3);
    s = s.substring(0, s.length - 3);
    while (s.length > 2) {
      result = '${s.substring(s.length - 2)},$result';
      s = s.substring(0, s.length - 2);
    }
    if (s.isNotEmpty) result = '$s,$result';

    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}
