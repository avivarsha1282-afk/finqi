import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import '../services/markets_service.dart';
import 'stock_detail_sheet.dart';
import 'watchlist_manager_screen.dart';

const _teal = Color(0xFF00C896);
const _red = Color(0xFFEF4444);

String _fmtPrice(double p) {
  if (p >= 1000) return '₹${NumberFormat('#,##,###', 'en_IN').format(p.round())}';
  return '₹${p.toStringAsFixed(2)}';
}



// ═══════════════════════════════════════════════════════════
// SECTORS HEATMAP — FIX 3: 2-column grid, not pills
// ═══════════════════════════════════════════════════════════

class SectorsHeatmap extends StatelessWidget {
  final Map<String, StockQuote> sectors;
  const SectorsHeatmap({super.key, required this.sectors});

  static const _descriptions = {
    'Auto': 'Vehicles & Parts', 'FMCG': 'Consumer Goods', 'Pharma': 'Healthcare',
    'Metal': 'Steel & Mining', 'Realty': 'Real Estate', 'Energy': 'Oil & Power',
  };

  double _heatIntensity(double changePct) {
    final abs = changePct.abs();
    if (abs > 2.0) return 0.30;
    if (abs > 1.0) return 0.20;
    if (abs > 0.5) return 0.12;
    return 0.08;
  }

  @override
  Widget build(BuildContext context) {
    if (sectors.isEmpty) return const SizedBox.shrink();
    final entries = sectors.entries.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SECTORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3.2),
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final e = entries[i];
            final q = e.value;
            final isPos = q.isPositive;
            final c = isPos ? _teal : _red;
            return GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => SectorDetailSheet(sectorName: e.key, sectorQuote: q)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: _heatIntensity(q.changePct)),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(_descriptions[e.key] ?? '', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.54))),
                  ])),
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${isPos ? "+" : ""}${q.changePct.toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('${isPos ? "+" : ""}${q.change.toStringAsFixed(0)} pts',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.70))),
                  ]),
                ])),
            );
          },
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// GAINERS / LOSERS — FIX 8: "1 stock" grammar
// ═══════════════════════════════════════════════════════════

class GainersLosersSection extends ConsumerWidget {
  final bool showGainers;
  final void Function(bool) onToggle;
  final void Function(StockQuote) onStockTap;
  const GainersLosersSection({super.key, required this.showGainers, required this.onToggle, required this.onStockTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movers = ref.watch(marketsMoversProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tab pills
        Row(children: [
          _TabPill(label: 'Gainers', active: showGainers, color: _teal, onTap: () => onToggle(true)),
          const SizedBox(width: 8),
          _TabPill(label: 'Losers', active: !showGainers, color: _red, onTap: () => onToggle(false)),
          const Spacer(),
          Text('Top 5', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
        ]),
        const SizedBox(height: 10),
        movers.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _teal)),
          error: (_, __) => Text('Unable to load', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38))),
          data: (d) {
            final list = showGainers ? d.gainers : d.losers;
            return Column(children: list.map((q) => StockRow(quote: q, onTap: () => onStockTap(q))).toList());
          },
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// VOLUME SHOCKERS
// ═══════════════════════════════════════════════════════════

class VolumeShockersSection extends ConsumerWidget {
  final void Function(StockQuote) onStockTap;
  const VolumeShockersSection({super.key, required this.onStockTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movers = ref.watch(marketsMoversProvider);
    return movers.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (d) {
        if (d.volumeShockers.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VOLUME SHOCKERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5)),
            const SizedBox(height: 10),
            ...d.volumeShockers.map((q) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: GestureDetector(
                onTap: () => onStockTap(q),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(q.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('${q.volumeRatio?.toStringAsFixed(1) ?? "?"}x avg volume',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                    Text(_fmtPrice(q.current), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('${q.isPositive ? "+" : ""}${q.changePct.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, color: q.isPositive ? _teal : _red)),
                  ]),
                ])),
            )),
          ]),
        );
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════
// NEWS — FIX 6: sentiment bars + first source only
// ═══════════════════════════════════════════════════════════

class NewsSection extends ConsumerWidget {
  const NewsSection({super.key});

  Color _sentimentColor(String s) {
    if (s == 'POSITIVE') return _teal;
    if (s == 'NEGATIVE') return _red;
    return Colors.white.withValues(alpha: 0.24);
  }

  String _firstSource(String sources) => sources.split(',').first.trim(); // FIX 6

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(marketsNewsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MARKET NEWS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5)),
        const SizedBox(height: 10),
        news.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _teal)),
          error: (_, __) => Text('News unavailable', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38))),
          data: (items) => Column(children: items.map((n) => Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // FIX 6: Sentiment color bar
              Container(
                width: 3, height: 40,
                decoration: BoxDecoration(
                  color: _sentimentColor(n.sentiment),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.headline, maxLines: 2, overflow: TextOverflow.ellipsis, // FIX 4C
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
                const SizedBox(height: 4),
                Row(children: [
                  Flexible(child: Text(_firstSource(n.source), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38)))),
                  Text(' · ${n.timeAgo}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
                ]),
              ])),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: Colors.white.withValues(alpha: 0.24), size: 14),
            ]),
          )).toList()),
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// IPO SECTION — FIX 7: hide GMP when 0
// ═══════════════════════════════════════════════════════════

class IPOSection extends ConsumerStatefulWidget {
  const IPOSection({super.key});
  @override
  ConsumerState<IPOSection> createState() => _IPOSectionState();
}

class _IPOSectionState extends ConsumerState<IPOSection> {
  bool _showRecent = false;

  @override
  Widget build(BuildContext context) {
    final ipo = ref.watch(marketsIPOProvider);
    return ipo.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.upcoming.isEmpty && data.recentListings.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.rocket_launch_outlined, size: 14, color: _teal),
              const SizedBox(width: 6),
              Text('IPO TRACKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5)),
            ]),
            // Upcoming
            if (data.upcoming.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Upcoming', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70))),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: data.upcoming.map((ipo) => Container(
                  width: 200, margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(ipo.companyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (ipo.category == 'SME' ? Colors.amber : _teal).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4)),
                      child: Text(ipo.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: ipo.category == 'SME' ? Colors.amber : _teal)),
                    ),
                    const SizedBox(height: 6),
                    Text(ipo.priceRange, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${ipo.openDate} — ${ipo.closeDate}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                    // FIX 7: only show GMP when non-zero
                    if (ipo.gmpPct != null && ipo.gmpPct != 0) ...[
                      const SizedBox(height: 4),
                      Text('GMP: ${ipo.gmpPct! > 0 ? "+" : ""}${ipo.gmpPct!.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: ipo.gmpPct! >= 0 ? _teal : _red)),
                    ],
                    if (ipo.minInvestment != null) ...[
                      const SizedBox(height: 4),
                      Text('Min: ${_fmtPrice(ipo.minInvestment!.toDouble())}',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                    ],
                  ]),
                )).toList()),
              ),
            ],
            // Recent listings
            if (data.recentListings.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showRecent = !_showRecent),
                child: Row(children: [
                  Text('Recent Listings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70))),
                  Icon(_showRecent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.38), size: 18),
                ]),
              ),
              if (_showRecent) ...[
                const SizedBox(height: 8),
                ...data.recentListings.map((ipo) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(ipo.companyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Listed ${ipo.listingDate}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      Text(_fmtPrice(ipo.currentPrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('${ipo.listingGain >= 0 ? "+" : ""}${ipo.listingGain.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: ipo.listingGain >= 0 ? _teal : _red)),
                    ]),
                  ]),
                )),
              ],
            ],
          ]),
        );
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════
// WATCHLIST — FIX 8: grammar fix
// ═══════════════════════════════════════════════════════════

class WatchlistSection extends ConsumerStatefulWidget {
  final void Function(StockQuote) onStockTap;
  const WatchlistSection({super.key, required this.onStockTap});
  @override
  ConsumerState<WatchlistSection> createState() => _WatchlistSectionState();
}

class _WatchlistSectionState extends ConsumerState<WatchlistSection> {
  Map<String, StockQuote>? _quotes;
  bool _loading = false;

  @override
  void initState() { super.initState(); _fetchQuotes(); }

  Future<void> _fetchQuotes() async {
    final wl = ref.read(watchlistProvider);
    if (wl.isEmpty) { if (mounted) setState(() => _loading = false); return; }
    setState(() => _loading = true);
    try {
      final quotes = await MarketsService.instance.getWatchlistQuotes(wl.map((s) => s.symbol).toList());
      if (mounted) setState(() { _quotes = quotes; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final wl = ref.watch(watchlistProvider);
    final count = wl.length;

    // Portfolio summary
    double portfolioValue = 0, portfolioCost = 0;
    for (final stock in wl) {
      if (stock.qty != null && stock.qty! > 0 && stock.avgBuyPrice != null) {
        final q = _quotes?[stock.symbol];
        if (q != null) {
          portfolioValue += q.current * stock.qty!;
          portfolioCost += stock.avgBuyPrice! * stock.qty!;
        }
      }
    }
    final hasPnl = portfolioCost > 0;
    final pnl = portfolioValue - portfolioCost;
    final pnlPct = portfolioCost > 0 ? (pnl / portfolioCost * 100) : 0.0;

    final artha = ref.watch(arthaMarketProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bookmark_outlined, size: 14, color: _teal),
          const SizedBox(width: 6),
          Text('WATCHLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.5)),
          const Spacer(),
          // FIX 8: proper grammar
          Text('$count ${count == 1 ? 'stock' : 'stocks'}',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
        ]),
        const SizedBox(height: 10),
        // Portfolio summary card
        if (hasPnl) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
            child: Column(children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Portfolio Value', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
                  Text(_fmtPrice(portfolioValue), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Text('P&L', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
                  Text('${pnl >= 0 ? "+" : ""}${_fmtPrice(pnl.abs())} (${pnlPct.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pnl >= 0 ? _teal : _red)),
                ]),
              ]),
              artha.when(
                data: (a) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.psychology_outlined, color: _teal, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Artha's view: ${a.sipAdvice}", style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.70)))),
                    ]),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ]),
          ),
        ],
        if (_loading)
          const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _teal))
        else if (wl.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No stocks in watchlist', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38))),
          ))
        else ...[
          ...wl.map((stock) {
            final quote = _quotes?[stock.symbol];
            if (quote == null) return const SizedBox.shrink();
            return StockRow(quote: quote, onTap: () => widget.onStockTap(quote));
          }),
        ],
        const SizedBox(height: 10),
        Center(child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const WatchlistManagerScreen())),
          child: const Text('+ Add More Stocks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _teal)),
        )),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// SHARED: StockRow
// ═══════════════════════════════════════════════════════════

class StockRow extends StatelessWidget {
  final StockQuote quote;
  final VoidCallback onTap;
  const StockRow({super.key, required this.quote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = quote.isPositive ? _teal : _red;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(quote.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(quote.cleanSymbol, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text(_fmtPrice(quote.current),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('${quote.isPositive ? "+" : ""}${quote.changePct.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
          ]),
        ]),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// TAB PILL (shared)
// ═══════════════════════════════════════════════════════════

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _TabPill({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.white.withValues(alpha: 0.12))),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? color : Colors.white.withValues(alpha: 0.38))),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// SECTOR DETAIL SHEET
// ═══════════════════════════════════════════════════════════

class SectorDetailSheet extends StatefulWidget {
  final String sectorName;
  final StockQuote sectorQuote;
  const SectorDetailSheet({super.key, required this.sectorName, required this.sectorQuote});
  @override
  State<SectorDetailSheet> createState() => _SectorDetailSheetState();
}

class _SectorDetailSheetState extends State<SectorDetailSheet> {
  List<StockQuote>? _stocks;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    try {
      final stocks = await MarketsService.instance.getSectorStocks(widget.sectorName);
      if (mounted) setState(() { _stocks = stocks; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.sectorQuote;
    final c = q.isPositive ? _teal : _red;
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.85, minChildSize: 0.3,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _teal.withValues(alpha: 0.20)))),
        child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 14, 20, 32), children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Text('NIFTY ${widget.sectorName.toUpperCase()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            Text('${q.isPositive ? "+" : ""}${q.changePct.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c)),
          ]),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _teal))
          else if (_stocks != null) ...() {
            // BUG 2 fix: filter out ₹0 stocks
            final valid = _stocks!.where((s) => s.current > 0).toList();
            final unavailable = _stocks!.where((s) => s.current <= 0).toList();
            return [
              ...valid.map((s) => StockRow(quote: s, onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (_) => StockDetailSheet(quote: s));
              })),
              // Show "unavailable" for ₹0 stocks
              ...unavailable.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Text(s.displayName, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.38)))),
                  Text('Data unavailable', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.24))),
                ]),
              )),
            ];
          }()
        ]),
      ),
    );
  }
}
