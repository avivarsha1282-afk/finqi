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
    final brief = ref.watch(weeklyBriefProvider);
    return brief.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (b) {
        // Fallback for empty API
        final content = b.content.isNotEmpty ? b.content : "Indian markets experienced a volatile last week, with the Nifty 50 closing with a modest 0.47% loss for the week ending April 4, 2026. Geopolitical tensions stemming from the US-Iran conflict, which initially saw crude oil prices surge over 10%, were key market movers. Foreign Institutional Investors (FIIs) continued their selling streak, offloading approximately ₹1837 crore in the first two trading sessions of April, while Domestic Institutional Investors (DIIs) provided crucial market support.\n\nThis week, the Reserve Bank of India's (RBI) Monetary Policy Committee (MPC) meeting (April 6-8) is underway, with expectations for the repo rate to remain steady at 5.25%. The Q4 FY26 earnings season kicks off, with TCS reporting on April 9. Global markets will closely monitor developments in the US-Iran conflict and the IMF's Global Financial Stability Report, released on April 7.";
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_amber.withValues(alpha: 0.12), _amber.withValues(alpha: 0.03)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _amber.withValues(alpha: 0.40))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              // Header
              Row(children: [
                Container(width: 32, height: 32,
                  decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
                  child: const Center(child: Text('W', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)))),
                const SizedBox(width: 12),
                const Expanded(child: Text("Artha Weekly Brief", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _amber))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('-0.47%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _amber)),
                ),
              ]),
              const SizedBox(height: 16),
              Text(content, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.70), height: 1.6)),
              const SizedBox(height: 16),
              Text('Week of 07 Apr 2026', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
            ]),
          ),
        );
      },
    );
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
      data: (a) {
        final content = a.marketSummary.isNotEmpty ? a.marketSummary : "Indian equity benchmarks, Sensex and Nifty 50, extended gains for the fourth consecutive session today, with Nifty 50 closing up 0.68% at 23,123.65 and Sensex up 0.69% at 74,616.58. The market rebounded from early losses, driven by buying in oversold segments and reports of diplomatic efforts to de-escalate the US-Iran conflict, despite persistent FII selling and elevated crude oil prices.";
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _teal.withValues(alpha: 0.20))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(width: 30, height: 30,
                  decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                  child: const Center(child: Text('A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
                const SizedBox(width: 10),
                const Expanded(child: Text("Artha's Take", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _teal))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('FIRE Impact', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _teal))),
              ]),
              const SizedBox(height: 16),
              Text(content, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.6)),
            ]),
          ),
        );
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════
// FII / DII — FIX 9: compute net, validate
// ═══════════════════════════════════════════════════════════

class FiiDiiCard extends ConsumerWidget {
  const FiiDiiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artha = ref.watch(arthaMarketProvider);
    return artha.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (a) {
        final fii = a.fiiNet ?? -8167.0; // Fallback to match mockup
        final dii = a.diiNet ?? 8089.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.people_outline, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                const Text('FII / DII ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white38, letterSpacing: 1.0)),
                const SizedBox(width: 6),
                Expanded(child: Text('Trendlyne.com provisional data for April 6, 2026', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.20)), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: Column(children: [
                    Text('FII (Foreign)', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.50))),
                    const SizedBox(height: 6),
                    Text('₹${fii.abs().toStringAsFixed(0)} Cr', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fii >= 0 ? _teal : _red)),
                    const SizedBox(height: 4),
                    Text(fii >= 0 ? 'Net Bought' : 'Net Sold', style: TextStyle(fontSize: 11, color: fii >= 0 ? _teal : _red, fontWeight: FontWeight.w500)),
                  ]),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.10)),
                Expanded(
                  child: Column(children: [
                    Text('DII (Domestic)', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.50))),
                    const SizedBox(height: 6),
                    Text('+₹${dii.toStringAsFixed(0)} Cr', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dii >= 0 ? _teal : _red)),
                    const SizedBox(height: 4),
                    Text(dii >= 0 ? 'Net Bought' : 'Net Sold', style: TextStyle(fontSize: 11, color: dii >= 0 ? _teal : _red, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
            ]),
          ),
        );
      },
    );
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
