import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import 'stock_detail_sheet.dart';
import 'markets_widgets.dart';
import 'markets_widgets_2.dart';

const _bg = Color(0xFF0A0A0A);

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});
  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> with TickerProviderStateMixin {
  bool _showGainers = true;
  late AnimationController _pulseCtrl;
  String _istTime = '';
  Timer? _clockTimer;

  // Alert banner state
  String? _alertBannerText;
  String? _alertBannerPrice;
  Timer? _alertDismissTimer;

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
  void dispose() { _clockTimer?.cancel(); _alertDismissTimer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _openStockSheet(StockQuote q) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StockDetailSheet(quote: q));
  }

  void _showAlertBanner(String stockName, double current, double target) {
    if (!mounted) return;
    setState(() {
      _alertBannerText = '$stockName hit your target!';
      _alertBannerPrice = '₹${current.toStringAsFixed(0)} ≤ ₹${target.toStringAsFixed(0)}';
    });
    _alertDismissTimer?.cancel();
    _alertDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() { _alertBannerText = null; _alertBannerPrice = null; });
    });
  }

  void _checkAlerts(Map<String, StockQuote>? quotes) {
    if (quotes == null) return;
    final wl = ref.read(watchlistProvider);
    for (final stock in wl) {
      if (stock.alertPrice != null && stock.alertPrice! > 0) {
        final q = quotes[stock.symbol];
        if (q != null && q.current > 0 && q.current <= stock.alertPrice!) {
          _showAlertBanner(stock.displayName, q.current, stock.alertPrice!);
          return; // show one at a time
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(marketsOverviewProvider);
    final countdown = ref.watch(refreshCountdownProvider);

    // Check alert prices on each overview refresh
    ref.listen(marketsOverviewProvider, (_, next) {
      next.whenData((overview) => _checkAlerts(overview.indices));
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        RefreshIndicator(
        color: const Color(0xFF00C896),
        onRefresh: () async {
          ref.invalidate(marketsOverviewProvider);
          ref.invalidate(marketsMoversProvider);
          ref.invalidate(arthaMarketProvider);
          ref.invalidate(marketsNewsProvider);
          ref.invalidate(marketsIPOProvider);
        },
        child: CustomScrollView(slivers: [
          // ── HEADER ──
          SliverToBoxAdapter(child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Markets', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  overviewAsync.when(
                    loading: () => Text('Loading...', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
                    error: (_, __) => const Text('• Offline', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                    data: (d) => Row(children: [
                      Text(d.isMarketOpen ? '• Live' : '• Closed', style: TextStyle(fontSize: 12,
                        color: d.isMarketOpen ? const Color(0xFF00C896) : Colors.white.withValues(alpha: 0.38))),
                      Text(' · Last close data', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.24))),
                    ]),
                  ),
                ]),
                const Spacer(),
                Text('$_istTime IST', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
                const SizedBox(width: 8),
                _CountdownBadge(seconds: countdown, pulse: _pulseCtrl),
              ]),
            ),
          )),

          // ── WEEKLY BRIEF ──
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(child: const WeeklyBriefCard()),

          // ── GLOBAL INDICES ──
          SliverToBoxAdapter(child: overviewAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (d) => GlobalIndicesStrip(globalIndices: d.global),
          )),
          
          // ── FII/DII ──
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(child: FiiDiiCard()),

          // ── ARTHA CARD ──
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(child: ArthaCard()),

          // ── COMMODITIES ──
          SliverToBoxAdapter(child: overviewAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (d) => CommoditiesStrip(commodities: d.commodities),
          )),

          // ── SENTIMENT ──
          SliverToBoxAdapter(child: overviewAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (d) => SentimentBar(overview: d),
          )),

          // ── INDICES ──
          SliverToBoxAdapter(child: overviewAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (d) => IndicesStrip(indices: d.indices, onTap: _openStockSheet),
          )),

          // ── SECTORS HEATMAP ──
          SliverToBoxAdapter(child: overviewAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (d) => SectorsHeatmap(sectors: d.sectors),
          )),

          // ── GAINERS / LOSERS ──
          SliverToBoxAdapter(child: GainersLosersSection(
            showGainers: _showGainers,
            onToggle: (v) => setState(() => _showGainers = v),
            onStockTap: _openStockSheet,
          )),

          // ── NEWS ──
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(child: NewsSection()),

          // ── IPO TRACKER ──
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(child: const IPOSection()),

          // ── WATCHLIST ──
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(child: WatchlistSection(onStockTap: _openStockSheet)),

          // ── DISCLAIMER ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Text(
              'Market data delayed ~15 minutes via Yahoo Finance. FinIQ Markets is for informational and educational purposes only. Nothing on this screen constitutes investment advice. Consult a SEBI-registered investment advisor before making investment decisions.',
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.24), height: 1.5),
              textAlign: TextAlign.center,
            ),
          )),
        ]),
      ),
      // ── Alert Banner (in-app notification) ──
      if (_alertBannerText != null)
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: AnimatedSlide(
              offset: Offset.zero,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: () => setState(() { _alertBannerText = null; _alertBannerPrice = null; }),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.40)),
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFF00C896), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(_alertBannerText!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      if (_alertBannerPrice != null)
                        Text(_alertBannerPrice!, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.70))),
                    ])),
                    Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.38), size: 16),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// COUNTDOWN BADGE
// ═══════════════════════════════════════════════════════════

class _CountdownBadge extends StatelessWidget {
  final int seconds;
  final AnimationController pulse;
  const _CountdownBadge({required this.seconds, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00C896).withValues(alpha: 0.20 + pulse.value * 0.10), width: 1.5),
        ),
        child: Center(child: Text('$seconds', style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF00C896)))),
      ),
    );
  }
}
