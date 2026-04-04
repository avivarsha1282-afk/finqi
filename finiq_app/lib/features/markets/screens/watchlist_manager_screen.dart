import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import '../services/markets_service.dart';

/// Watchlist Manager — Search + Browse Nifty 50
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

  // Full Nifty 50 list for browsing
  static const _nifty50 = {
    'Reliance': 'RELIANCE.NS',
    'TCS': 'TCS.NS',
    'HDFC Bank': 'HDFCBANK.NS',
    'Infosys': 'INFY.NS',
    'ICICI Bank': 'ICICIBANK.NS',
    'HUL': 'HINDUNILVR.NS',
    'ITC': 'ITC.NS',
    'Kotak Bank': 'KOTAKBANK.NS',
    'L&T': 'LT.NS',
    'Bajaj Finance': 'BAJFINANCE.NS',
    'Wipro': 'WIPRO.NS',
    'Asian Paints': 'ASIANPAINT.NS',
    'Maruti': 'MARUTI.NS',
    'Titan': 'TITAN.NS',
    'Sun Pharma': 'SUNPHARMA.NS',
    'Nestle': 'NESTLEIND.NS',
    'M&M': 'M&M.NS',
    'Axis Bank': 'AXISBANK.NS',
    'HCL Tech': 'HCLTECH.NS',
    'ONGC': 'ONGC.NS',
    'SBI': 'SBIN.NS',
    'Bharti Airtel': 'BHARTIARTL.NS',
    'Adani Ent': 'ADANIENT.NS',
    'Bajaj Finserv': 'BAJAJFINSV.NS',
    'Power Grid': 'POWERGRID.NS',
    'NTPC': 'NTPC.NS',
    'Tata Motors': 'TATAMOTORS.NS',
    'Tata Steel': 'TATASTEEL.NS',
    'Coal India': 'COALINDIA.NS',
    'JSW Steel': 'JSWSTEEL.NS',
    'IndusInd Bank': 'INDUSINDBK.NS',
    'Tech Mahindra': 'TECHM.NS',
    'Grasim': 'GRASIM.NS',
    'Dr Reddy': 'DRREDDY.NS',
    'Cipla': 'CIPLA.NS',
    'BPCL': 'BPCL.NS',
    'Eicher Motors': 'EICHERMOT.NS',
    'Divis Lab': 'DIVISLAB.NS',
    'Hindalco': 'HINDALCO.NS',
    'Hero Moto': 'HEROMOTOCO.NS',
    'Apollo Hosp': 'APOLLOHOSP.NS',
    'UPL': 'UPL.NS',
    'Tata Consumer': 'TATACONSUM.NS',
    'Brit Industries': 'BRITANNIA.NS',
    'Shriram Finance': 'SHRIRAMFIN.NS',
    'Adani Ports': 'ADANIPORTS.NS',
    'Bajaj Auto': 'BAJAJ-AUTO.NS',
    'Ultratech': 'ULTRACEMCO.NS',
    'HDFC Life': 'HDFCLIFE.NS',
    'SBI Life': 'SBILIFE.NS',
    'Dmart': 'DMART.NS',
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

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
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _toggleStock(String displayName, String symbol) {
    final notifier = ref.read(watchlistProvider.notifier);
    if (notifier.isWatching(symbol)) {
      notifier.removeStock(symbol);
    } else {
      notifier.addStock(WatchlistStock(symbol: symbol, displayName: displayName));
    }
    setState(() {}); // rebuild bookmark icons
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    const teal = Color(0xFF00C896);
    final sortedEntries = _nifty50.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Add to Watchlist', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: teal, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search stocks or symbols...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
              prefixIcon: Icon(Icons.search_outlined, color: Colors.white.withValues(alpha: 0.38)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),

        // Watching count
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('Watching ${watchlist.length} stocks',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
            const Spacer(),
          ])),
        const SizedBox(height: 8),

        // Content
        Expanded(child: _buildContent(sortedEntries, teal)),
      ]),
    );
  }

  Widget _buildContent(List<MapEntry<String, String>> sortedEntries, Color teal) {
    // Show search results if searching
    if (_searchResults != null) {
      if (_searching) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF00C896)));
      }
      if (_searchResults!.isEmpty) {
        return Center(child: Text('No stocks found', style: TextStyle(color: Colors.white.withValues(alpha: 0.38))));
      }
      return ListView.builder(
        itemCount: _searchResults!.length,
        itemBuilder: (_, i) {
          final r = _searchResults![i];
          final isWatching = ref.read(watchlistProvider.notifier).isWatching(r.symbol);
          return _StockListTile(
            displayName: r.displayName, symbol: r.symbol,
            isWatching: isWatching, onTap: () => _toggleStock(r.displayName, r.symbol));
        },
      );
    }

    // Default: browse Nifty 50
    return ListView(children: [
      // Divider label
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('BROWSE NIFTY 50', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1))),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
        ]),
      ),
      ...sortedEntries.map((e) {
        final isWatching = ref.read(watchlistProvider.notifier).isWatching(e.value);
        return _StockListTile(
          displayName: e.key, symbol: e.value,
          isWatching: isWatching, onTap: () => _toggleStock(e.key, e.value));
      }),
    ]);
  }
}


class _StockListTile extends StatelessWidget {
  final String displayName;
  final String symbol;
  final bool isWatching;
  final VoidCallback onTap;
  const _StockListTile({required this.displayName, required this.symbol,
    required this.isWatching, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          Text(symbol.replaceAll('.NS', ''), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
        ])),
        IconButton(
          icon: Icon(isWatching ? Icons.bookmark_rounded : Icons.bookmark_border_outlined,
            color: isWatching ? teal : Colors.white.withValues(alpha: 0.38)),
          onPressed: onTap),
      ]),
    );
  }
}
