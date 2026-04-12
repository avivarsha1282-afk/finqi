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
import '../../../l10n/t.dart';
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
        appBar: AppBar(
        title: Text(t(ref, 'fire_planner'), style: AppTextStyles.subheading),
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: AppColors.primaryTeal)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.textTertiary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      t(ref, 'fire_error_retry'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _fetchPlan(ref.read(fireInputProvider)),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(t(ref, 'retry')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    final plan = _plan!;
    final isGoalAchieved = plan.goalStatus == 'ALREADY_ACHIEVED';
    final isNoSipNeeded = plan.goalStatus == 'NO_SIP_NEEDED';
    final isGoalMet = isGoalAchieved || isNoSipNeeded;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
        title: Text(t(ref, 'fire_planner'), style: AppTextStyles.subheading),
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
              final statusText = isGoalAchieved
                  ? 'Goal Already Achieved! \u{1F389}'
                  : 'Monthly SIP needed: ${CurrencyFormatter.compact(plan.requiredMonthlySip)}';
              Share.share('\u{1F525} My FIRE Plan (FinIQ)\n'
                  'Target: ${CurrencyFormatter.compact(plan.targetCorpus)}\n'
                  'Timeline: ${plan.targetYears} years\n'
                  '$statusText\n\n'
                  'Plan your FIRE journey with FinIQ! \u{1F4CA}');
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

            // ══════════════════════════════════════════════════
            // GOAL ACHIEVED / NO SIP NEEDED — Celebration Card
            // ══════════════════════════════════════════════════
            if (isGoalAchieved)
              _buildGoalAchievedCard(plan).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.95, 0.95))
            else if (isNoSipNeeded)
              _buildNoSipNeededCard(plan).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.95, 0.95))
            else
              // ── Normal SIP Result Hero ──────────────────────
              _buildSipHeroCard(plan).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // ── Growth Chart with annotations ─────────────────
            const Text('PROJECTED GROWTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _buildGrowthChart(plan, isGoalMet),

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

            // ── Scenarios (hide if goal already achieved) ─────
            if (!isGoalAchieved) ...[
              const Text('FIRE SCENARIOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...plan.scenarios.map((s) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: s.isRecommended ? AppColors.primaryTeal.withValues(alpha: 0.08) : AppColors.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: s.isRecommended ? AppColors.primaryTeal.withValues(alpha: 0.3) : AppColors.borderColor),
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
                                    decoration: BoxDecoration(color: AppColors.primaryTeal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('REC', style: TextStyle(fontSize: 8, color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${s.years} years \u00b7 ${s.risk}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(CurrencyFormatter.monthly(s.monthlySip),
                          style: TextStyle(color: s.isRecommended ? AppColors.primaryTeal : Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
            ],

            // ── Artha message ─────────────────────────────────
            if (plan.arthaMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.05),
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
        color: Colors.black.withValues(alpha: 0.5),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
    ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // GOAL ACHIEVED CELEBRATION CARD (Section 4C)
  // ══════════════════════════════════════════════════════════
  Widget _buildGoalAchievedCard(FirePlanModel plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF00C896).withValues(alpha: 0.12), AppColors.cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00C896), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Goal Already Achieved! \u{1F389}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plan.goalStatusMessage.isNotEmpty)
            Text(plan.goalStatusMessage,
                style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16),

          // Savings vs Goal comparison row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your savings', style: TextStyle(fontSize: 11, color: Colors.white38)),
                      const SizedBox(height: 4),
                      Text(CurrencyFormatter.compact(plan.currentSavings),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF00C896))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Your goal', style: TextStyle(fontSize: 11, color: Colors.white38)),
                      const SizedBox(height: 4),
                      Text(CurrencyFormatter.compact(plan.targetCorpus),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // "Set a Higher Goal" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditDialog(context, ref, 'Target Corpus', plan.targetCorpus.toString(), (v) {
                ref.read(fireInputProvider.notifier).update(targetAmount: v);
              }),
              icon: const Icon(Icons.flag_rounded, size: 18),
              label: const Text('Set a Higher Goal \u2192', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // NO SIP NEEDED BADGE (Section 7C)
  // ══════════════════════════════════════════════════════════
  Widget _buildNoSipNeededCard(FirePlanModel plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primaryTeal.withValues(alpha: 0.12), AppColors.cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('\u20B90 / mo', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Your existing savings grow to', style: TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.compact(plan.projectedCorpus),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF00C896))),
          const SizedBox(height: 4),
          Text('in ${plan.targetYears} years', style: const TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('NO SIP NEEDED',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00C896), letterSpacing: 1)),
          ),
          if (plan.goalStatusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(plan.goalStatusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4)),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // NORMAL SIP HERO CARD (existing, with improved label colors)
  // ══════════════════════════════════════════════════════════
  Widget _buildSipHeroCard(FirePlanModel plan) {
    final labelColor = _sipLabelColor(plan.sipLabel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primaryTeal.withValues(alpha: 0.12), AppColors.cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
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
              color: labelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plan.sipLabel.replaceAll('_', ' '),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor),
            ),
          ),
          const SizedBox(height: 8),
          Text('at ${plan.estimatedReturn}% p.a. estimated return', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // GROWTH CHART with annotations (Section 7B)
  // ══════════════════════════════════════════════════════════
  Widget _buildGrowthChart(FirePlanModel plan, bool isGoalMet) {
    final spots = plan.growthData.map((d) => FlSpot(d.year.toDouble(), d.corpus)).toList();
    final maxY = spots.isEmpty ? 1000000.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final targetY = plan.targetCorpus;
    final startY = plan.currentSavings;

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          // Chart annotations row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start: ${CurrencyFormatter.compact(startY)}',
                    style: const TextStyle(fontSize: 10, color: Colors.white54)),
                if (isGoalMet)
                  const Text('\u2713 Goal exceeded', style: TextStyle(fontSize: 10, color: Color(0xFF00C896), fontWeight: FontWeight.w600))
                else
                  Text('Goal: ${CurrencyFormatter.compact(targetY)}',
                      style: const TextStyle(fontSize: 10, color: Colors.white54)),
                Text('Projected: ${CurrencyFormatter.compact(plan.projectedCorpus)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1000000,
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
                // Target goal dashed line
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (targetY > 0 && targetY < maxY * 1.2)
                      HorizontalLine(
                        y: targetY,
                        color: isGoalMet ? const Color(0xFF00C896).withValues(alpha: 0.3) : Colors.white24,
                        strokeWidth: 1,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: TextStyle(
                            fontSize: 9,
                            color: isGoalMet ? const Color(0xFF00C896) : Colors.white38,
                          ),
                          labelResolver: (_) => 'Goal: ${CurrencyFormatter.compact(targetY)}',
                        ),
                      ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryTeal,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: true, color: AppColors.primaryTeal.withValues(alpha: 0.08)),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (index == 0 || index == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.primaryTeal,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0, strokeColor: Colors.transparent);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

  // ── Dialogs ────────────────────────────────────────────────

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
            prefixText: '\u20B9 ',
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

  // ── Helpers ─────────────────────────────────────────────

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

  /// SIP label colors per Section 7A
  Color _sipLabelColor(String label) {
    switch (label) {
      case 'ALREADY_ACHIEVED': return const Color(0xFF00C896);
      case 'ALREADY_ACHIEVABLE': return const Color(0xFF00C896);
      case 'COMFORTABLE': return const Color(0xFF00C896);
      case 'MANAGEABLE': return const Color(0xFFFFC107);
      case 'STRETCH': return const Color(0xFFFF9800);
      case 'DIFFICULT': return const Color(0xFFF44336);
      default: return AppColors.primaryTeal;
    }
  }

  Color _achievabilityColor(String a) {
    switch (a) {
      case 'ACHIEVABLE': return AppColors.successGreen;
      case 'CHALLENGING': return AppColors.warningAmber;
      case 'STRETCH': return AppColors.warningAmber;
      default: return AppColors.dangerRed;
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
