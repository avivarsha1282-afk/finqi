import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import 'commodity_detail_sheet.dart';

const _teal = Color(0xFF00C896);
const _red = Color(0xFFEF4444);
const _amber = Color(0xFFFF9800);

String _fmtIndian(double v) => NumberFormat('#,##,###', 'en_IN').format(v.round());
String _fmtCommodity(double p) => '₹${NumberFormat('#,##,###', 'en_IN').format(p.round())}';


// ═══════════════════════════════════════════════════════════
// WEEKLY BRIEF — first-open-of-the-week Artha card
// ═══════════════════════════════════════════════════════════

class WeeklyBriefCard extends ConsumerStatefulWidget {
  const WeeklyBriefCard({super.key});
  @override
  ConsumerState<WeeklyBriefCard> createState() => _WeeklyBriefCardState();
}

class _WeeklyBriefCardState extends ConsumerState<WeeklyBriefCard> {
  bool _dismissed = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    // Show on first open of the week (Mon/Tue to catch late openers)
    final weekday = DateTime.now().weekday;
    if (weekday > 2) return const SizedBox.shrink(); // Wed-Sun: skip

    final brief = ref.watch(weeklyBriefProvider);
    return brief.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (b) {
        if (!b.available || b.content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_amber.withValues(alpha: 0.12), _amber.withValues(alpha: 0.03)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _amber.withValues(alpha: 0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              // Header
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: _amber.withValues(alpha: 0.20), shape: BoxShape.circle),
                  child: const Center(child: Text('W', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Artha's Weekly Brief", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _amber)),
                  Text(b.weekLabel, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                ])),
                // Dismiss
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.24), size: 18)),
              ]),
              const SizedBox(height: 12),
              // Content — truncated to 3 lines, expandable
              AnimatedSize(
                duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
                child: Text(b.content,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.6)),
              ),
              if (b.content.length > 120) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Read more →',
                    style: const TextStyle(fontSize: 12, color: _amber, fontWeight: FontWeight.w500))),
              ],
              // Mood badge
              if (b.mood.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _moodColor(b.mood).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text('MOOD: ${b.mood}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _moodColor(b.mood), letterSpacing: 0.5))),
                  if (b.niftyWeekChange != null) ...[
                    const SizedBox(width: 8),
                    Text('Nifty: ${b.niftyWeekChange! >= 0 ? "+" : ""}${b.niftyWeekChange!.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, color: b.niftyWeekChange! >= 0 ? _teal : _red, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ],
            ]),
          ),
        );
      },
    );
  }

  Color _moodColor(String m) {
    if (m.contains('BULL')) return _teal;
    if (m.contains('BEAR')) return _red;
    if (m.contains('CAUTIOUS')) return _amber;
    return Colors.white38;
  }
}


// ═══════════════════════════════════════════════════════════
// ARTHA CARD — 2-line truncation + Read more (FIX 4A)
// ═══════════════════════════════════════════════════════════

class ArthaCard extends ConsumerStatefulWidget {
  const ArthaCard({super.key});
  @override
  ConsumerState<ArthaCard> createState() => _ArthaCardState();
}

class _ArthaCardState extends ConsumerState<ArthaCard> {
  bool _summaryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final artha = ref.watch(arthaMarketProvider);
    return artha.when(
      loading: () => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(height: 100, decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)))),
      error: (_, __) => const SizedBox.shrink(),
      data: (a) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_teal.withValues(alpha: 0.10), _teal.withValues(alpha: 0.03)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _teal.withValues(alpha: 0.20))),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(width: 30, height: 30,
                  decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                  child: const Center(child: Text('A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
                const SizedBox(width: 10),
                const Expanded(child: Text("Artha's Take", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _teal))),
                // FIRE IMPACT chip
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: const Text('FIRE Impact', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _teal))),
                ),
              ]),
              const SizedBox(height: 12),
              // Market summary — FIX 4A: max 2 lines + Read more
              Text(a.marketSummary,
                maxLines: _summaryExpanded ? null : 2,
                overflow: _summaryExpanded ? null : TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.6)),
              if (a.marketSummary.length > 80 && !_summaryExpanded) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _summaryExpanded = true),
                  child: const Text('Read more →', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w500))),
              ],
              if (_summaryExpanded && a.marketSummary.length > 80) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _summaryExpanded = false),
                  child: const Text('Show less', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w500))),
              ],
              const SizedBox(height: 12),
              // FIX 4B: Chips with maxLines 2
              _ArthaChip(icon: Icons.local_fire_department_outlined, label: 'FIRE IMPACT', content: a.fireImpact),
              const SizedBox(height: 8),
              _ArthaChip(icon: Icons.trending_up_outlined, label: 'SIP THIS MONTH', content: a.sipAdvice),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ArthaChip extends StatelessWidget {
  final IconData icon; final String label; final String content;
  const _ArthaChip({required this.icon, required this.label, required this.content});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _teal, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.38), letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(content, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.70), height: 1.4),
          maxLines: 2, overflow: TextOverflow.ellipsis), // FIX 4B: max 2 lines
      ])),
    ]));
}


// ═══════════════════════════════════════════════════════════
// FII / DII — FIX 9: compute net, validate
// ═══════════════════════════════════════════════════════════

class FiiDiiCard extends ConsumerWidget {
  const FiiDiiCard({super.key});

  bool _isValid(double fii, double dii) => fii.abs() <= 15000 && dii.abs() <= 15000;

  String _formatCr(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artha = ref.watch(arthaMarketProvider);
    return artha.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (a) {
        if (a.fiiNet == null && a.diiNet == null) return const SizedBox.shrink();
        final fii = a.fiiNet ?? 0;
        final dii = a.diiNet ?? 0;
        if (!_isValid(fii, dii)) return const SizedBox.shrink(); // FIX 9: hide if invalid
        final net = fii + dii; // FIX 9: always compute from FII + DII
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
            child: Row(children: [
              _fiiDiiCol('FII', fii),
              Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.08),
                margin: const EdgeInsets.symmetric(horizontal: 12)),
              _fiiDiiCol('DII', dii),
              Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.08),
                margin: const EdgeInsets.symmetric(horizontal: 12)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('NET', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.24), letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text('${net >= 0 ? "+" : ""}₹${_formatCr(net.abs())}Cr',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: net >= 0 ? _teal : _red)),
              ]),
            ])),
        );
      });
  }

  Widget _fiiDiiCol(String label, double net) {
    final isPos = net >= 0;
    final c = isPos ? _teal : _red;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.54), letterSpacing: 0.8)),
      const SizedBox(height: 2),
      Text('${isPos ? "+" : ""}₹${_formatCr(net.abs())}Cr',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
    ]);
  }
}


// ═══════════════════════════════════════════════════════════
// COMMODITIES — FIX 2: no fixed height, FIX 5: tappable
// ═══════════════════════════════════════════════════════════

class CommoditiesStrip extends StatelessWidget {
  final Map<String, CommodityQuote> commodities;
  const CommoditiesStrip({super.key, required this.commodities});

  static const _icons = {'Gold': Icons.diamond_outlined, 'Silver': Icons.auto_awesome,
    'Crude Oil': Icons.local_fire_department_outlined, 'Natural Gas': Icons.whatshot_outlined};

  @override
  Widget build(BuildContext context) {
    if (commodities.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('COMMODITIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5))),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: commodities.entries.map((e) {
            final q = e.value;
            final c = q.isPositive ? _teal : _red;
            final sign = q.isPositive ? '+' : '';
            return GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => CommodityDetailSheet(name: e.key, quote: q)), // FIX 5
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 130),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [ // FIX 2
                  Row(children: [
                    Icon(_icons[e.key] ?? Icons.attach_money, size: 14, color: Colors.white.withValues(alpha: 0.54)),
                    const SizedBox(width: 4),
                    Flexible(child: Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.70)), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Text(_fmtCommodity(q.priceINR),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text('$sign${q.changePct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
                    const SizedBox(width: 4),
                    Flexible(child: Text(q.unit, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.24)),
                      overflow: TextOverflow.ellipsis)),
                  ]),
                ])));
          }).toList()),
        ),
      ]));
  }
}


// ═══════════════════════════════════════════════════════════
// SENTIMENT BAR — FIX 10: 5-segment visual
// ═══════════════════════════════════════════════════════════

class SentimentBar extends StatelessWidget {
  final MarketOverview overview;
  const SentimentBar({super.key, required this.overview});

  int _filledSegments(String s) {
    switch (s) {
      case 'VERY_BULLISH': return 5;
      case 'BULLISH': return 4;
      case 'NEUTRAL': return 3;
      case 'BEARISH': return 2;
      case 'VERY_BEARISH': return 1;
      default: return 3;
    }
  }

  Color _segmentColor(String s) => s.contains('BULL') ? _teal : (s.contains('BEAR') ? _red : Colors.white38);

  String _label(String s) {
    if (s.contains('BULL')) return 'BULLISH';
    if (s.contains('BEAR')) return 'BEARISH';
    return 'SIDEWAYS';
  }

  @override
  Widget build(BuildContext context) {
    final s = overview.sentiment;
    final c = _segmentColor(s);
    final filled = _filledSegments(s);
    final updated = overview.lastUpdated.length > 16 ? overview.lastUpdated.substring(11, 16) : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.trending_up, size: 14, color: c),
          const SizedBox(width: 6),
          Text('Market sentiment: ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
          Text(_label(s), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
          const Spacer(),
          // 5 segment bar
          Row(children: List.generate(5, (i) => Container(
            width: 20, height: 5,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
            decoration: BoxDecoration(
              color: i < filled ? c : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3)),
          ))),
          if (overview.isMarketOpen) ...[
            const SizedBox(width: 6),
            Container(width: 5, height: 5,
              decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle)),
          ],
          if (updated.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text('Updated $updated IST', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.24))),
          ],
        ])),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// INDICES STRIP — FIX 2: no fixed height, ConstrainedBox
// ═══════════════════════════════════════════════════════════

class IndicesStrip extends StatelessWidget {
  final Map<String, StockQuote> indices;
  final void Function(StockQuote) onTap;
  const IndicesStrip({super.key, required this.indices, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('INDICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5))),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: indices.entries.map((e) {
            final q = e.value;
            final c = q.isPositive ? _teal : _red;
            final name = e.key.replaceAll('_', ' ');
            return GestureDetector(
              onTap: () => onTap(q),
              child: ConstrainedBox( // FIX 2
                constraints: const BoxConstraints(minWidth: 150, maxWidth: 160),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [ // FIX 2
                    Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.70))),
                    const SizedBox(height: 6),
                    Text(_fmtIndian(q.current),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(q.isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                        color: c, size: 16),
                      Text('${q.isPositive ? "+" : ""}${q.changePct.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                    ]),
                    if (q.sparkline.length >= 2) ...[
                      const SizedBox(height: 6),
                      SizedBox(width: double.infinity, height: 36,
                        child: CustomPaint(painter: SparkPainter(data: q.sparkline, isPositive: q.isPositive))),
                    ],
                  ])),
              ),
            );
          }).toList()),
        ),
      ]));
  }
}


// ═══════════════════════════════════════════════════════════
// SPARKLINE PAINTER (shared)
// ═══════════════════════════════════════════════════════════

class SparkPainter extends CustomPainter {
  final List<double> data; final bool isPositive;
  SparkPainter({required this.data, required this.isPositive});
  @override
  void paint(Canvas canvas, Size s) {
    if (data.length < 2) return;
    final c = isPositive ? _teal : _red;
    double mn = data[0], mx = data[0];
    for (final v in data) { if (v < mn) mn = v; if (v > mx) mx = v; }
    final r = mx - mn;
    if (r == 0) return;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * s.width;
      final y = s.height - ((data[i] - mn) / r) * s.height;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, Paint()..color = c..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant SparkPainter old) => old.data != data;
}
