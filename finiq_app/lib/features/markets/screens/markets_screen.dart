import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import '../services/markets_service.dart';
import 'watchlist_manager_screen.dart';
import 'stock_detail_sheet.dart';

const _teal = Color(0xFF00C896);
const _red = Color(0xFFF44336);
const _bg = Color(0xFF0A0A0A);

String _fmtIndex(double v) => NumberFormat('#,##0', 'en_IN').format(v.round());
String _fmtPrice(double p) {
  if (p >= 1000) return '₹${NumberFormat('#,##0', 'en_IN').format(p.round())}';
  return '₹${p.toStringAsFixed(2)}';
}

const _sectorDescriptions = {
  'Auto': 'Vehicles & Parts', 'FMCG': 'Consumer Goods', 'Pharma': 'Healthcare',
  'Metal': 'Steel & Mining', 'Realty': 'Real Estate', 'Energy': 'Oil & Power',
};

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});
  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> with TickerProviderStateMixin {
  bool _showGainers = true;
  bool _showImpact = false;
  late AnimationController _pulseCtrl;
  String _istTime = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    if (mounted) setState(() => _istTime = DateFormat('HH:mm').format(now));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _clockTimer?.cancel(); super.dispose(); }

  void _refresh() {
    ref.invalidate(marketsOverviewProvider);
    ref.invalidate(marketsMoversProvider);
    ref.read(refreshCountdownProvider.notifier).reset();
  }

  String _nextOpen() {
    final now = DateTime.now();
    final wd = now.weekday;
    final h = now.hour; final m = now.minute;
    if (wd == 5 && (h > 15 || (h == 15 && m > 30))) return 'Opens Monday 9:15 AM IST';
    if (wd == 6 || wd == 7) return 'Opens Monday 9:15 AM IST';
    if (h < 9 || (h == 9 && m < 15)) return 'Opens today at 9:15 AM IST';
    if (h > 15 || (h == 15 && m > 30)) return 'Opens tomorrow 9:15 AM IST';
    return '';
  }

  void _showStockDetail(StockQuote q) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => StockDetailSheet(quote: q));

  void _showSectorSheet(String name, StockQuote q) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _SectorDetailSheet(sectorName: name, sectorQuote: q));

  @override
  Widget build(BuildContext context) {
    final ov = ref.watch(marketsOverviewProvider);
    final cd = ref.watch(refreshCountdownProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(slivers: [
        // ── APP BAR ──
        SliverAppBar(
          backgroundColor: _bg, surfaceTintColor: Colors.transparent,
          floating: true, pinned: true, elevation: 0, automaticallyImplyLeading: false,
          expandedHeight: 0,
          title: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('Markets', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                ov.when(
                  loading: () => _dot(Colors.white24),
                  error: (_, __) => _dot(Colors.white24),
                  data: (d) => d.isMarketOpen
                    ? ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)),
                        child: _dot(_teal))
                    : _dot(Colors.white38),
                ),
                const SizedBox(width: 5),
                ov.when(
                  loading: () => Text('Loading...', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
                  error: (_, __) => const Text('Offline', style: TextStyle(fontSize: 12, color: _red)),
                  data: (d) => Text(d.isMarketOpen ? 'Live · NSE/BSE' : 'Closed · Last close data',
                    style: TextStyle(fontSize: 12, color: d.isMarketOpen ? _teal : Colors.white.withValues(alpha: 0.38))),
                ),
              ]),
            ]),
            const Spacer(),
            Text('$_istTime IST', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _refresh,
              child: SizedBox(width: 32, height: 32, child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: cd / 30, strokeWidth: 1.5,
                  color: _teal.withValues(alpha: 0.50), backgroundColor: Colors.white.withValues(alpha: 0.08)),
                Text('$cd', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
              ])),
            ),
          ]),
        ),

        // ── MARKET HOURS BAR ──
        SliverToBoxAdapter(child: ov.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (d) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
            child: Row(children: [
              Icon(Icons.schedule_outlined, color: Colors.white.withValues(alpha: 0.24), size: 13),
              const SizedBox(width: 6),
              Expanded(child: Text(d.isMarketOpen ? 'Market open until 3:30 PM IST' : _nextOpen(),
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38)))),
              Text('~15 min delay', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
            ]),
          ),
        )),

        // ── GLOBAL MARKET SNAPSHOT ──
        SliverToBoxAdapter(child: ov.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (d) => d.global.isNotEmpty ? _GlobalStrip(global: d.global) : const SizedBox.shrink(),
        )),

        // ── ARTHA INTELLIGENCE CARD ──
        SliverToBoxAdapter(child: _ArthaCard(
          showImpact: _showImpact,
          onToggleImpact: () => setState(() => _showImpact = !_showImpact),
          niftyPct: ov.valueOrNull?.indices['NIFTY_50']?.changePct ?? 0,
        )),

        // ── MARKET SENTIMENT BAR ──
        SliverToBoxAdapter(child: ov.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (d) => _SentimentBar(overview: d),
        )),

        // ── INDICES ROW ──
        SliverToBoxAdapter(child: ov.when(
          loading: () => _shimmer(155),
          error: (_, __) => const _ErrorCard(msg: 'Could not load indices'),
          data: (d) => _IndicesRow(indices: d.indices, onTap: _showStockDetail, isOpen: d.isMarketOpen),
        )),

        // ── SECTORS HEATMAP ──
        SliverToBoxAdapter(child: ov.when(
          loading: () => _shimmer(120),
          error: (_, __) => const SizedBox.shrink(),
          data: (d) => _SectorsHeatmap(sectors: d.sectors, onTap: _showSectorSheet),
        )),

        // ── GAINERS & LOSERS ──
        SliverToBoxAdapter(child: _MoversSection(
          showGainers: _showGainers,
          onToggle: (v) => setState(() => _showGainers = v),
          onStockTap: _showStockDetail,
        )),

        // ── MARKET NEWS ──
        SliverToBoxAdapter(child: _NewsSection()),

        // ── WATCHLIST ──
        SliverToBoxAdapter(child: _WatchlistSection(onStockTap: _showStockDetail)),

        // ── DISCLAIMER FOOTER ──
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Text(
            'Market data delayed ~15 minutes via Yahoo Finance. '
            'FinIQ Markets is for informational and educational purposes only. '
            'Nothing on this screen constitutes investment advice. '
            'Consult a SEBI-registered investment advisor before making investment decisions.',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24), height: 1.5),
            textAlign: TextAlign.center),
        )),
      ]),
    );
  }

  Widget _dot(Color c) => Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  Widget _shimmer(double h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Container(height: h, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16))));
}


// ═══════════════════════════════════════════════════════════
class _ErrorCard extends StatelessWidget {
  final String msg;
  const _ErrorCard({required this.msg});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _red.withValues(alpha: 0.20))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: _red, size: 16), const SizedBox(width: 8),
      Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ])));
}


// ═══════════════════════════════════════════════════════════
// GLOBAL MARKET STRIP
// ═══════════════════════════════════════════════════════════
class _GlobalStrip extends StatelessWidget {
  final Map<String, StockQuote> global;
  const _GlobalStrip({required this.global});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(0, 8, 0, 0), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('GLOBAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.24), letterSpacing: 1))),
        const SizedBox(height: 6),
        SizedBox(height: 52, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: global.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final e = global.entries.elementAt(i);
            final q = e.value;
            final c = q.isPositive ? _teal : _red;
            final sign = q.isPositive ? '+' : '';
            return Container(
              width: 100, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(e.key, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text('$sign${q.changePct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                  const SizedBox(width: 2),
                  Icon(q.isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: c, size: 14),
                ]),
              ]),
            );
          },
        )),
      ],
    ));
  }
}


// ═══════════════════════════════════════════════════════════
// ARTHA INTELLIGENCE CARD (upgraded)
// ═══════════════════════════════════════════════════════════
class _ArthaCard extends ConsumerWidget {
  final bool showImpact;
  final VoidCallback onToggleImpact;
  final double niftyPct;
  const _ArthaCard({required this.showImpact, required this.onToggleImpact, required this.niftyPct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(arthaMarketProvider);

    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: async.when(
      loading: () => Container(height: 140, decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(20))),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _teal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _teal.withValues(alpha: 0.15))),
        child: const Row(children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _teal)),
          SizedBox(width: 10),
          Text("Artha is thinking...", style: TextStyle(color: _teal, fontSize: 13)),
        ])),
      data: (insight) {
        final sentColor = insight.sentiment == 'BULLISH' ? _teal
            : insight.sentiment == 'BEARISH' ? _red : Colors.white54;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_teal.withValues(alpha: 0.12), _teal.withValues(alpha: 0.04)]),
            border: Border.all(color: _teal.withValues(alpha: 0.25), width: 1.5),
            borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Stack(children: [
                const CircleAvatar(radius: 18, backgroundColor: _teal,
                  child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))),
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: _bg, shape: BoxShape.circle, border: Border.all(color: _bg, width: 2)),
                  child: const Icon(Icons.auto_awesome, color: _teal, size: 7))),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Artha's Market Intelligence", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _teal)),
                Text('Updated ${insight.lastUpdated}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: sentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(insight.sentiment, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sentColor))),
            ]),
            const SizedBox(height: 14),
            Text(insight.marketSummary, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 12),
            // Full-width chips (column, not row)
            _ArthaChip(icon: Icons.local_fire_department_outlined, label: 'FIRE IMPACT', text: insight.fireImpact),
            const SizedBox(height: 8),
            _ArthaChip(icon: Icons.trending_up_outlined, label: 'SIP THIS MONTH', text: insight.sipAdvice),
            // Portfolio impact toggle
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onToggleImpact,
              child: Row(children: [
                Text(showImpact ? 'Hide portfolio impact' : 'See portfolio impact →',
                  style: const TextStyle(fontSize: 13, color: _teal, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(showImpact ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _teal, size: 18),
              ])),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _PortfolioImpact(niftyPct: niftyPct),
              crossFadeState: showImpact ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300)),
          ]),
        );
      },
    ));
  }
}

class _ArthaChip extends StatelessWidget {
  final IconData icon; final String label; final String text;
  const _ArthaChip({required this.icon, required this.label, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _teal, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.38), letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          maxLines: 3, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _PortfolioImpact extends StatelessWidget {
  final double niftyPct;
  const _PortfolioImpact({required this.niftyPct});
  @override
  Widget build(BuildContext context) {
    const monthlySip = 25000.0;
    const equityExposure = 0.60;
    final estimatedCorpus = monthlySip * 12 * 5;
    final equityPortion = estimatedCorpus * equityExposure;
    final impact = equityPortion * (niftyPct / 100);
    final sign = impact >= 0 ? '+' : '';
    final color = impact >= 0 ? _teal : _red;

    return Padding(padding: const EdgeInsets.only(top: 10), child: Column(children: [
      Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nifty $sign${niftyPct.toStringAsFixed(2)}% today', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.54))),
          const SizedBox(height: 2),
          Text('Est. SIP corpus impact:', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$sign₹${NumberFormat('#,##0', 'en_IN').format(impact.abs().round())}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text('(~60% equity)', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
        ]),
      ]),
      const SizedBox(height: 6),
      Text('Based on ₹25,000/mo SIP · Moderate equity allocation · Estimated impact only',
        style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.24))),
      const SizedBox(height: 4),
      Text('For informational purposes only. Not investment advice.',
        style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.20))),
    ]));
  }
}


// ═══════════════════════════════════════════════════════════
// SENTIMENT BAR
// ═══════════════════════════════════════════════════════════
class _SentimentBar extends StatelessWidget {
  final MarketOverview overview;
  const _SentimentBar({required this.overview});
  @override
  Widget build(BuildContext context) {
    final nPct = overview.indices['NIFTY_50']?.changePct ?? 0;
    int filled;
    String label; Color color;
    if (nPct > 0.5) { filled = 5; label = 'BULLISH DAY 🟢'; color = _teal; }
    else if (nPct > 0.2) { filled = 4; label = 'MILDLY POSITIVE ↗'; color = _teal; }
    else if (nPct > -0.2) { filled = 3; label = 'SIDEWAYS ↔'; color = Colors.white54; }
    else if (nPct > -0.5) { filled = 2; label = 'MILDLY NEGATIVE ↘'; color = _red; }
    else { filled = 1; label = 'BEARISH DAY 🔴'; color = _red; }

    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_teal.withValues(alpha: 0.04), Colors.transparent]),
        borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text('Market Mood: ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const Spacer(),
        Row(children: List.generate(5, (i) => Container(
          width: 24, height: 6, margin: EdgeInsets.only(left: i > 0 ? 3 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: i < filled
              ? (filled >= 3 ? _teal : _red).withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.08))))),
      ]),
    ));
  }
}


// ═══════════════════════════════════════════════════════════
// INDICES ROW
// ═══════════════════════════════════════════════════════════
class _IndicesRow extends StatelessWidget {
  final Map<String, StockQuote> indices;
  final void Function(StockQuote) onTap;
  final bool isOpen;
  const _IndicesRow({required this.indices, required this.onTap, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateLabel = isOpen ? 'Today, ${DateFormat('MMM d').format(today)}'
        : 'Last close, ${DateFormat('MMM d').format(today)}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Text('INDICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.2)),
          const Spacer(),
          Text(dateLabel, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
        ])),
      SizedBox(height: 160, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: indices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final q = indices.values.elementAt(i);
          final c = q.isPositive ? _teal : _red;
          final sign = q.isPositive ? '+' : '';
          return GestureDetector(
            onTap: () => onTap(q),
            child: Container(
              width: 160, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: c.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.54), letterSpacing: 0.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('₹${_fmtIndex(q.current)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(q.isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: c, size: 16),
                  Text('$sign${q.changePct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
                  const SizedBox(width: 4),
                  Text('($sign${q.change.toStringAsFixed(0)})', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                ]),
                const SizedBox(height: 10),
                Expanded(child: _Sparkline(data: q.sparkline, isPositive: q.isPositive)),
              ])),
          );
        },
      )),
    ]);
  }
}


// ═══════════════════════════════════════════════════════════
// SPARKLINE
// ═══════════════════════════════════════════════════════════
class _Sparkline extends StatelessWidget {
  final List<double> data; final bool isPositive;
  const _Sparkline({required this.data, required this.isPositive});
  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox();
    return CustomPaint(painter: _SparkPainter(data: data, isPositive: isPositive), size: Size.infinite);
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data; final bool isPositive;
  _SparkPainter({required this.data, required this.isPositive});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final c = isPositive ? _teal : _red;
    final mn = data.reduce(min); final mx = data.reduce(max); final r = mx - mn;
    if (r == 0) return;
    final path = Path(); final fill = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - mn) / r) * size.height;
      if (i == 0) { path.moveTo(x, y); fill.moveTo(x, size.height); fill.lineTo(x, y); }
      else { path.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill.lineTo(size.width, size.height); fill.close();
    canvas.drawPath(fill, Paint()..color = c.withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = c..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.data != data;
}


// ═══════════════════════════════════════════════════════════
// SECTORS HEATMAP
// ═══════════════════════════════════════════════════════════
class _SectorsHeatmap extends StatelessWidget {
  final Map<String, StockQuote> sectors;
  final void Function(String, StockQuote) onTap;
  const _SectorsHeatmap({required this.sectors, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SECTORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.2)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.6,
          children: sectors.entries.map((e) {
            final q = e.value; final p = q.changePct;
            final bgColor = p > 1.5 ? _teal.withValues(alpha: 0.20) : p > 0 ? _teal.withValues(alpha: 0.10)
                : p < -1.5 ? _red.withValues(alpha: 0.20) : p < 0 ? _red.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.06);
            final borderColor = p > 0 ? _teal.withValues(alpha: 0.40) : p < 0 ? _red.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.10);
            final tc = p >= 0 ? _teal : _red;
            final sign = p >= 0 ? '+' : '';
            return GestureDetector(
              onTap: () => onTap(e.key, q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: bgColor, border: Border.all(color: borderColor)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_sectorDescriptions[e.key] ?? '', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$sign${p.toStringAsFixed(2)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc)),
                    Text('$sign${q.change.toStringAsFixed(0)} pts', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
                  ]),
                ])));
          }).toList()),
      ]));
  }
}


// ═══════════════════════════════════════════════════════════
// MOVERS (Gainers/Losers)
// ═══════════════════════════════════════════════════════════
class _MoversSection extends ConsumerWidget {
  final bool showGainers; final ValueChanged<bool> onToggle; final void Function(StockQuote) onStockTap;
  const _MoversSection({required this.showGainers, required this.onToggle, required this.onStockTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketsMoversProvider);
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _TabPill(label: '▲ Top Gainers', selected: showGainers, color: _teal, onTap: () => onToggle(true)),
          const SizedBox(width: 10),
          _TabPill(label: '▼ Top Losers', selected: !showGainers, color: _red, onTap: () => onToggle(false)),
        ]),
        const SizedBox(height: 12),
        async.when(
          loading: () => Column(children: List.generate(5, (_) => Container(
            height: 64, margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12))))),
          error: (_, __) => const _ErrorCard(msg: 'Could not load market movers'),
          data: (m) {
            final list = showGainers ? m.gainers : m.losers;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(key: ValueKey(showGainers), children: list.map((q) =>
                _StockRow(quote: q, onTap: () => onStockTap(q))).toList()));
          }),
      ]));
  }
}

class _TabPill extends StatelessWidget {
  final String label; final bool selected; final Color color; final VoidCallback onTap;
  const _TabPill({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: selected ? color.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.10)),
      borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
      color: selected ? color : Colors.white.withValues(alpha: 0.38)))));
}


// ═══════════════════════════════════════════════════════════
// STOCK ROW (shared)
// ═══════════════════════════════════════════════════════════
class _StockRow extends StatelessWidget {
  final StockQuote quote; final VoidCallback onTap; final Widget? trailing;
  const _StockRow({required this.quote, required this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) {
    final c = quote.isPositive ? _teal : _red;
    final sign = quote.isPositive ? '+' : '';
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(children: [
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(quote.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(quote.cleanSymbol, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
        ])),
        SizedBox(width: 60, height: 30, child: _Sparkline(data: quote.sparkline, isPositive: quote.isPositive)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmtPrice(quote.current), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text('$sign${quote.changePct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
          const SizedBox(height: 2),
          Text('$sign₹${quote.change.abs().toStringAsFixed(1)}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
        ]),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ])));
  }
}


// ═══════════════════════════════════════════════════════════
// NEWS SECTION
// ═══════════════════════════════════════════════════════════
class _NewsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketsNewsProvider);
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('MARKET NEWS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.2)),
          const Spacer(),
          Text('via Gemini', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.24))),
        ]),
        const SizedBox(height: 12),
        async.when(
          loading: () => Column(children: List.generate(3, (_) => Container(
            height: 64, margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12))))),
          error: (_, __) => Text('News unavailable', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38))),
          data: (news) => Column(children: news.map((n) {
            final barColor = n.sentiment == 'POSITIVE' ? _teal : n.sentiment == 'NEGATIVE' ? _red : Colors.white.withValues(alpha: 0.24);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 3, height: 48, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.headline, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(n.source, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                    Text(' · ${n.timeAgo}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
                  ]),
                ])),
              ]));
          }).toList()),
        ),
      ]));
  }
}


// ═══════════════════════════════════════════════════════════
// WATCHLIST
// ═══════════════════════════════════════════════════════════
class _WatchlistSection extends ConsumerStatefulWidget {
  final void Function(StockQuote) onStockTap;
  const _WatchlistSection({required this.onStockTap});
  @override
  ConsumerState<_WatchlistSection> createState() => _WatchlistSectionState();
}

class _WatchlistSectionState extends ConsumerState<_WatchlistSection> {
  Map<String, StockQuote>? _quotes;
  bool _loading = false;

  @override
  void initState() { super.initState(); _fetchQuotes(); }

  void _fetchQuotes() async {
    final wl = ref.read(watchlistProvider);
    if (wl.isEmpty) return;
    setState(() => _loading = true);
    try {
      final q = await MarketsService.instance.getWatchlistQuotes(wl.map((s) => s.symbol).toList());
      if (mounted) setState(() { _quotes = q; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final wl = ref.watch(watchlistProvider);
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('MY WATCHLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.2)),
          const Spacer(),
          Text('${wl.length} stocks', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistManagerScreen()));
              _fetchQuotes();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
              child: Text('Manage →', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.54))))),
        ]),
        const SizedBox(height: 12),
        if (wl.isEmpty) Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Icon(Icons.bookmark_border_outlined, color: Colors.white.withValues(alpha: 0.24), size: 40),
            const SizedBox(height: 12),
            Text('Add stocks to track', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.38))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistManagerScreen()));
                _fetchQuotes();
              },
              child: const Text('Browse Nifty 50 →', style: TextStyle(fontSize: 13, color: _teal, fontWeight: FontWeight.w500))),
          ]))
        else if (_loading) ...List.generate(wl.length.clamp(0, 5), (_) => Container(
          height: 60, margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12))))
        else ...[
          ...wl.map((stock) {
            final quote = _quotes?[stock.symbol];
            if (quote == null) return const SizedBox.shrink();
            return Dismissible(
              key: ValueKey(stock.symbol),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
                color: _red.withValues(alpha: 0.15),
                child: const Icon(Icons.delete_outline, color: _red)),
              confirmDismiss: (_) async {
                ref.read(watchlistProvider.notifier).removeStock(stock.symbol);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Removed ${stock.displayName}'),
                    action: SnackBarAction(label: 'Undo', onPressed: () =>
                      ref.read(watchlistProvider.notifier).addStock(stock)),
                    duration: const Duration(seconds: 3)));
                }
                return false; // already removed
              },
              child: _StockRow(quote: quote, onTap: () => widget.onStockTap(quote),
                trailing: const Icon(Icons.bookmark_rounded, color: _teal, size: 20)),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistManagerScreen()));
              _fetchQuotes();
            },
            child: const Center(child: Text('+ Add More Stocks', style: TextStyle(fontSize: 13, color: _teal, fontWeight: FontWeight.w500)))),
        ],
      ]));
  }
}


// ═══════════════════════════════════════════════════════════
// SECTOR DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════
class _SectorDetailSheet extends StatefulWidget {
  final String sectorName; final StockQuote sectorQuote;
  const _SectorDetailSheet({required this.sectorName, required this.sectorQuote});
  @override
  State<_SectorDetailSheet> createState() => _SectorDetailSheetState();
}

class _SectorDetailSheetState extends State<_SectorDetailSheet> {
  List<StockQuote>? _stocks;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  void _load() async {
    try {
      final stocks = await MarketsService.instance.getSectorStocks(widget.sectorName);
      if (mounted) setState(() { _stocks = stocks; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.sectorQuote;
    final c = q.isPositive ? _teal : _red;
    final sign = q.isPositive ? '+' : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.92, minChildSize: 0.4,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
        child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 14, 20, 32), children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(widget.sectorName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(_sectorDescriptions[widget.sectorName] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('$sign${q.changePct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c))),
            const SizedBox(width: 8),
            Text('Since last close', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
          ]),
          const SizedBox(height: 20),
          if (q.sparkline.length >= 2) SizedBox(height: 140, child: _Sparkline(data: q.sparkline, isPositive: q.isPositive)),
          const SizedBox(height: 20),
          Text('Top stocks in this sector', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.54))),
          const SizedBox(height: 8),
          if (_loading) ...List.generate(3, (_) => Container(
            height: 60, margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12))))
          else if (_stocks != null) ..._stocks!.map((s) => _StockRow(quote: s, onTap: () {
            Navigator.pop(context);
            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
              builder: (_) => StockDetailSheet(quote: s));
          })),
        ]),
      ),
    );
  }
}
