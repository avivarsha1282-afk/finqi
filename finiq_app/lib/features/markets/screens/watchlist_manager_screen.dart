import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import '../services/markets_service.dart';

const _teal = Color(0xFF00C896);


/// Watchlist Manager — Search + Browse Nifty 50 + Alert Price + Portfolio
class WatchlistManagerScreen extends ConsumerStatefulWidget {
  const WatchlistManagerScreen({super.key});
  @override
  ConsumerState<WatchlistManagerScreen> createState() => _WatchlistManagerState();
}

class _WatchlistManagerState extends ConsumerState<WatchlistManagerScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<SearchResult>? _searchResults;
  bool _searching = false;

  static const _nifty50 = {
    'Reliance': 'RELIANCE.NS', 'TCS': 'TCS.NS', 'HDFC Bank': 'HDFCBANK.NS',
    'Infosys': 'INFY.NS', 'ICICI Bank': 'ICICIBANK.NS', 'HUL': 'HINDUNILVR.NS',
    'ITC': 'ITC.NS', 'Kotak Bank': 'KOTAKBANK.NS', 'L&T': 'LT.NS',
    'Bajaj Finance': 'BAJFINANCE.NS', 'Wipro': 'WIPRO.NS', 'Asian Paints': 'ASIANPAINT.NS',
    'Maruti': 'MARUTI.NS', 'Titan': 'TITAN.NS', 'Sun Pharma': 'SUNPHARMA.NS',
    'Nestle': 'NESTLEIND.NS', 'M&M': 'M&M.NS', 'Axis Bank': 'AXISBANK.NS',
    'HCL Tech': 'HCLTECH.NS', 'ONGC': 'ONGC.NS', 'SBI': 'SBIN.NS',
    'Bharti Airtel': 'BHARTIARTL.NS', 'Adani Ent': 'ADANIENT.NS',
    'Bajaj Finserv': 'BAJAJFINSV.NS', 'Power Grid': 'POWERGRID.NS',
    'NTPC': 'NTPC.NS', 'Tata Motors': 'TATAMOTORS.NS', 'Tata Steel': 'TATASTEEL.NS',
    'Coal India': 'COALINDIA.NS', 'JSW Steel': 'JSWSTEEL.NS',
    'IndusInd Bank': 'INDUSINDBK.NS', 'Tech Mahindra': 'TECHM.NS',
    'Grasim': 'GRASIM.NS', 'Dr Reddy': 'DRREDDY.NS', 'Cipla': 'CIPLA.NS',
    'BPCL': 'BPCL.NS', 'Eicher Motors': 'EICHERMOT.NS', 'Divis Lab': 'DIVISLAB.NS',
    'Hindalco': 'HINDALCO.NS', 'Hero Moto': 'HEROMOTOCO.NS',
    'Apollo Hosp': 'APOLLOHOSP.NS', 'UPL': 'UPL.NS', 'Tata Consumer': 'TATACONSUM.NS',
    'Brit Industries': 'BRITANNIA.NS', 'Shriram Finance': 'SHRIRAMFIN.NS',
    'Adani Ports': 'ADANIPORTS.NS', 'Bajaj Auto': 'BAJAJ-AUTO.NS',
    'Ultratech': 'ULTRACEMCO.NS', 'HDFC Life': 'HDFCLIFE.NS',
    'SBI Life': 'SBILIFE.NS', 'Dmart': 'DMART.NS',
  };

  @override
  void dispose() { _debounce?.cancel(); _searchController.dispose(); super.dispose(); }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _searchResults = null; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await MarketsService.instance.searchStocks(query);
        if (mounted) setState(() { _searchResults = results; _searching = false; });
      } catch (_) { if (mounted) setState(() => _searching = false); }
    });
  }

  void _toggleStock(String displayName, String symbol) {
    final notifier = ref.read(watchlistProvider.notifier);
    if (notifier.isWatching(symbol)) {
      notifier.removeStock(symbol);
    } else {
      notifier.addStock(WatchlistStock(symbol: symbol, displayName: displayName));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    final sortedEntries = _nifty50.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Manage Watchlist', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: _teal, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController, onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search stocks or symbols...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
              prefixIcon: Icon(Icons.search_outlined, color: Colors.white.withValues(alpha: 0.38)),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),

        // Tab: My Watchlist vs Browse
        if (_searchResults == null) ...[
          // My watchlist section
          if (watchlist.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('MY WATCHLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1)),
                const Spacer(),
                Text('${watchlist.length} ${watchlist.length == 1 ? "stock" : "stocks"}',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
              ])),
            const SizedBox(height: 8),
            Expanded(child: ListView(children: [
              ...watchlist.map((stock) => _WatchlistStockTile(
                stock: stock,
                onRemove: () => _toggleStock(stock.displayName, stock.symbol),
                onUpdateAlert: (price) => ref.read(watchlistProvider.notifier)
                    .updateStock(stock.symbol, alertPrice: price),
                onClearAlert: () => ref.read(watchlistProvider.notifier).clearAlert(stock.symbol),
                onUpdatePortfolio: (qty, avgBuy) => ref.read(watchlistProvider.notifier)
                    .updateStock(stock.symbol, qty: qty, avgBuyPrice: avgBuy),
              )),
              const SizedBox(height: 16),
              // Browse section below
              _browseSectionHeader(),
              ...sortedEntries.map((e) {
                final isWatching = ref.read(watchlistProvider.notifier).isWatching(e.value);
                return _SimpleStockTile(
                  displayName: e.key, symbol: e.value,
                  isWatching: isWatching, onTap: () => _toggleStock(e.key, e.value));
              }),
            ])),
          ] else ...[
            Expanded(child: _buildBrowseList(sortedEntries)),
          ],
        ],

        // Search results
        if (_searchResults != null)
          Expanded(child: _buildSearchResults()),
      ]),
    );
  }

  Widget _browseSectionHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('BROWSE NIFTY 50', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1))),
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
    ]),
  );

  Widget _buildBrowseList(List<MapEntry<String, String>> entries) => ListView(children: [
    _browseSectionHeader(),
    ...entries.map((e) {
      final isWatching = ref.read(watchlistProvider.notifier).isWatching(e.value);
      return _SimpleStockTile(
        displayName: e.key, symbol: e.value,
        isWatching: isWatching, onTap: () => _toggleStock(e.key, e.value));
    }),
  ]);

  Widget _buildSearchResults() {
    if (_searching) return const Center(child: CircularProgressIndicator(color: _teal));
    if (_searchResults!.isEmpty) {
      return Center(child: Text('No stocks found', style: TextStyle(color: Colors.white.withValues(alpha: 0.38))));
    }
    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (_, i) {
        final r = _searchResults![i];
        final isWatching = ref.read(watchlistProvider.notifier).isWatching(r.symbol);
        return _SimpleStockTile(
          displayName: r.displayName, symbol: r.symbol,
          isWatching: isWatching, onTap: () => _toggleStock(r.displayName, r.symbol));
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════
// WATCHLIST STOCK TILE — with alert price + portfolio
// ═══════════════════════════════════════════════════════════

class _WatchlistStockTile extends StatefulWidget {
  final WatchlistStock stock;
  final VoidCallback onRemove;
  final void Function(double?) onUpdateAlert;
  final VoidCallback onClearAlert;
  final void Function(int, double) onUpdatePortfolio;

  const _WatchlistStockTile({
    required this.stock, required this.onRemove,
    required this.onUpdateAlert, required this.onClearAlert,
    required this.onUpdatePortfolio});

  @override
  State<_WatchlistStockTile> createState() => _WatchlistStockTileState();
}

class _WatchlistStockTileState extends State<_WatchlistStockTile> {
  bool _expanded = false;
  bool _ownsStock = false;
  final _alertCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _avgBuyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.stock;
    if (s.alertPrice != null) _alertCtrl.text = s.alertPrice!.toStringAsFixed(0);
    if (s.qty != null && s.qty! > 0) {
      _ownsStock = true;
      _qtyCtrl.text = s.qty!.toString();
      if (s.avgBuyPrice != null) _avgBuyCtrl.text = s.avgBuyPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() { _alertCtrl.dispose(); _qtyCtrl.dispose(); _avgBuyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Main row
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(widget.stock.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              Text(widget.stock.symbol.replaceAll('.NS', '').replaceAll('.BO', ''),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
              // Show alert badge if set
              if (widget.stock.alertPrice != null) ...[
                const SizedBox(height: 2),
                Text('Alert: ≤₹${widget.stock.alertPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w500)),
              ],
            ])),
            Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: Colors.white.withValues(alpha: 0.38), size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.bookmark_rounded, color: _teal, size: 20),
              onPressed: widget.onRemove,
              padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        ),

        // Expanded: alert price + portfolio
        if (_expanded) ...[
          const SizedBox(height: 12),
          // Alert price
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(Icons.notifications_outlined, color: Colors.white.withValues(alpha: 0.38), size: 14),
                const SizedBox(width: 6),
                Text('Set alert price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.54))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: SizedBox(height: 36, child: TextField(
                  controller: _alertCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2400',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.24)),
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 14),
                    filled: true, fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final v = double.tryParse(_alertCtrl.text);
                    widget.onUpdateAlert(v);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Set', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _teal))),
                ),
                if (widget.stock.alertPrice != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () { _alertCtrl.clear(); widget.onClearAlert(); },
                    child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.38), size: 16)),
                ],
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          // "I own this" toggle + portfolio inputs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.38), size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text('I own this stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.54)))),
                SizedBox(height: 24, child: Switch.adaptive(
                  value: _ownsStock,
                  activeTrackColor: _teal.withValues(alpha: 0.40),
                  activeThumbColor: _teal,
                  onChanged: (v) {
                    setState(() => _ownsStock = v);
                    if (!v) { widget.onUpdatePortfolio(0, 0); }
                  },
                )),
              ]),
              if (_ownsStock) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _MiniField(controller: _qtyCtrl, label: 'Qty', hint: '10')),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniField(controller: _avgBuyCtrl, label: 'Avg Buy ₹', hint: '2300')),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final qty = int.tryParse(_qtyCtrl.text) ?? 0;
                      final avg = double.tryParse(_avgBuyCtrl.text) ?? 0;
                      if (qty > 0 && avg > 0) widget.onUpdatePortfolio(qty, avg);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _teal))),
                  ),
                ]),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// MINI INPUT FIELD
// ═══════════════════════════════════════════════════════════

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _MiniField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.38))),
    const SizedBox(height: 4),
    SizedBox(height: 34, child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.20)),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
    )),
  ]);
}


// ═══════════════════════════════════════════════════════════
// SIMPLE STOCK TILE (for browse/search)
// ═══════════════════════════════════════════════════════════

class _SimpleStockTile extends StatelessWidget {
  final String displayName;
  final String symbol;
  final bool isWatching;
  final VoidCallback onTap;
  const _SimpleStockTile({required this.displayName, required this.symbol,
    required this.isWatching, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          Text(symbol.replaceAll('.NS', ''), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
        ])),
        IconButton(
          icon: Icon(isWatching ? Icons.bookmark_rounded : Icons.bookmark_border_outlined,
            color: isWatching ? _teal : Colors.white.withValues(alpha: 0.38)),
          onPressed: onTap),
      ]),
    );
  }
}
