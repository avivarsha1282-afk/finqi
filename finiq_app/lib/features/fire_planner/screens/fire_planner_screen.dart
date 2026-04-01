import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../models/fire_plan_model.dart';
import '../../../services/api_service.dart';
import '../../language/providers/language_provider.dart';
import '../providers/fire_provider.dart';

class FirePlannerScreen extends ConsumerStatefulWidget {
  const FirePlannerScreen({super.key});

  @override
  ConsumerState<FirePlannerScreen> createState() => _FirePlannerScreenState();
}

class _FirePlannerScreenState extends ConsumerState<FirePlannerScreen> {
  FirePlanModel? _plan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlan(ref.read(fireInputProvider));
    });
  }

  Future<void> _fetchPlan(FireGoalInput input) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final p = await ApiService.instance.getFirePlan(
        targetAmount: input.targetAmount,
        targetYears: input.targetYears,
        currentSavings: input.currentSavings,
      );
      if (mounted) {
        setState(() {
          _plan = p;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FireGoalInput>(fireInputProvider, (prev, next) {
      if (prev != next) {
        _fetchPlan(next);
      }
    });

    final input = ref.watch(fireInputProvider);
    final lang = ref.watch(languageProvider);

    if (_plan == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: AppColors.primaryTeal)
              : const Text('Failed to calculate FIRE plan.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final plan = _plan!;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
        title: Text(lang == 'hi' ? 'FIRE प्लानर 🔥' : 'FIRE Planner 🔥', style: AppTextStyles.subheading),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryTeal),
            tooltip: 'Refresh',
            onPressed: () {
              _fetchPlan(input);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing FIRE plan...'), backgroundColor: AppColors.primaryTeal, duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () {
              Share.share('🔥 My FIRE Plan (FinIQ)\n'
                  'Target: ${CurrencyFormatter.compact(plan.targetCorpus)}\n'
                  'Timeline: ${plan.targetYears} years\n'
                  'Monthly SIP needed: ${CurrencyFormatter.compact(plan.requiredMonthlySip)}\n\n'
                  'Plan your FIRE journey with FinIQ! 📊');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input Card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR FIRE INPUTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _inputRow('Target Corpus', CurrencyFormatter.compact(input.targetAmount), () {
                    _showEditDialog(context, ref, 'Target Corpus', input.targetAmount.toString(), (v) {
                      ref.read(fireInputProvider.notifier).update(targetAmount: v);
                    });
                  }),
                  _inputRow('Timeline', '${input.targetYears} years', () {
                    _showTimelineDialog(context, ref, input.targetYears);
                  }),
                  _inputRow('Current Savings', CurrencyFormatter.compact(input.currentSavings), () {
                    _showEditDialog(context, ref, 'Current Savings', input.currentSavings.toString(), (v) {
                      ref.read(fireInputProvider.notifier).update(currentSavings: v);
                    });
                  }),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // ── SIP Result Hero ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.primaryTeal.withOpacity(0.12), AppColors.cardColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('REQUIRED MONTHLY SIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(CurrencyFormatter.monthly(plan.requiredMonthlySip),
                      style: AppTextStyles.financialLarge.copyWith(fontSize: 32)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _achievabilityColor(plan.achievability).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(plan.achievability.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _achievabilityColor(plan.achievability))),
                  ),
                  const SizedBox(height: 8),
                  Text('at ${plan.estimatedReturn}% p.a. estimated return', style: AppTextStyles.caption),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // ── Growth Chart ──────────────────────────────────
            const Text('PROJECTED GROWTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: plan.targetCorpus > 0 ? plan.targetCorpus / 4 : 1000000,
                    getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFF1F2937), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text('${DateTime.now().year + v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(CurrencyFormatter.compact(v), style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: plan.growthData.map((d) => FlSpot(d.year.toDouble(), d.corpus)).toList(),
                      isCurved: true,
                      color: AppColors.primaryTeal,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: AppColors.primaryTeal.withOpacity(0.08)),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 24),

            // ── Asset Allocation ──────────────────────────────
            const Text('RECOMMENDED ALLOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: plan.assetAllocation.map((a) {
                  final color = _hexToColor(a.colorHex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a.name, style: const TextStyle(color: Colors.white, fontSize: 14))),
                        Text('${a.percentage.toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 24),

            // ── Scenarios ─────────────────────────────────────
            const Text('FIRE SCENARIOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ...plan.scenarios.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: s.isRecommended ? AppColors.primaryTeal.withOpacity(0.08) : AppColors.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: s.isRecommended ? AppColors.primaryTeal.withOpacity(0.3) : AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(s.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              if (s.isRecommended) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('REC', style: TextStyle(fontSize: 8, color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${s.years} years · ${s.risk}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(CurrencyFormatter.monthly(s.monthlySip),
                        style: TextStyle(color: s.isRecommended ? AppColors.primaryTeal : Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),

            // ── Artha message ─────────────────────────────────
            if (plan.arthaMessage.isNotEmpty) ...[
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
                      constraints: const BoxConstraints(minHeight: 50),
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
                        child: Text(plan.arthaMessage, style: AppTextStyles.arthaQuote),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Disclaimer ────────────────────────────────────
            const SizedBox(height: 24),
            const Text(
              'This is financial education, not SEBI-registered investment advice. Past performance doesn\'t guarantee future returns. Consult a certified financial planner before investing.',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.5),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
    if (_isLoading)
      Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
    ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String title, String currentValue, Function(double) onSave) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: AppColors.primaryTeal),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = parseAmount(ctrl.text);
              if (val > 0) {
                onSave(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showTimelineDialog(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (_) {
        int years = current;
        return StatefulBuilder(
          builder: (_, setState) => AlertDialog(
            backgroundColor: AppColors.cardElevated,
            title: const Text('Target Timeline', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$years years', style: const TextStyle(color: AppColors.primaryTeal, fontSize: 24, fontWeight: FontWeight.w700)),
                Slider(
                  value: years.toDouble(), min: 1, max: 30, divisions: 29,
                  activeColor: AppColors.primaryTeal,
                  onChanged: (v) => setState(() => years = v.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(fireInputProvider.notifier).update(targetYears: years);
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryTeal),
          ],
        ),
      ),
    );
  }

  Color _achievabilityColor(String a) {
    switch (a) {
      case 'ACHIEVABLE': return AppColors.successGreen;
      case 'STRETCH': return AppColors.warningAmber;
      default: return AppColors.dangerRed;
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
