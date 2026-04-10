import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_models.dart';
import '../services/markets_service.dart';

final marketsOverviewProvider = FutureProvider.autoDispose<MarketOverview>((ref) async {
  return MarketsService.instance.getOverview();
});

final marketsMoversProvider = FutureProvider.autoDispose<MarketMovers>((ref) async {
  return MarketsService.instance.getMovers();
});

final arthaMarketProvider = FutureProvider.autoDispose<ArthaMarketInsight>((ref) async {
  return MarketsService.instance.getArthaInsight();
});

final marketsNewsProvider = FutureProvider.autoDispose<List<MarketNews>>((ref) async {
  return MarketsService.instance.getNews();
});

final marketsIPOProvider = FutureProvider.autoDispose<IPOData>((ref) async {
  return MarketsService.instance.getIPOs();
});

final weeklyBriefProvider = FutureProvider.autoDispose<WeeklyBrief>((ref) async {
  return MarketsService.instance.getWeeklyBrief();
});

// ── Watchlist ──
class WatchlistNotifier extends StateNotifier<List<WatchlistStock>> {
  WatchlistNotifier() : super([]) { _loadFromPrefs(); }
  static const _key = 'finiq_watchlist';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        state = list.map((v) => WatchlistStock.fromJson(v as Map<String, dynamic>)).toList();
      }
    } catch (e) { debugPrint('[Watchlist] Load error: $e'); }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.map((s) => s.toJson()).toList()));
    } catch (e) { debugPrint('[Watchlist] Save error: $e'); }
  }

  Future<void> addStock(WatchlistStock stock) async {
    if (state.any((s) => s.symbol == stock.symbol)) return;
    state = [...state, stock];
    await _saveToPrefs();
  }

  Future<void> removeStock(String symbol) async {
    state = state.where((s) => s.symbol != symbol).toList();
    await _saveToPrefs();
  }

  bool isWatching(String symbol) => state.any((s) => s.symbol == symbol);

  WatchlistStock? getStock(String symbol) {
    final idx = state.indexWhere((s) => s.symbol == symbol);
    return idx >= 0 ? state[idx] : null;
  }

  Future<void> updateStock(String symbol, {double? alertPrice, int? qty, double? avgBuyPrice}) async {
    final idx = state.indexWhere((s) => s.symbol == symbol);
    if (idx < 0) return;
    final old = state[idx];
    final updated = WatchlistStock(
      symbol: old.symbol,
      displayName: old.displayName,
      alertPrice: alertPrice ?? old.alertPrice,
      qty: qty ?? old.qty,
      avgBuyPrice: avgBuyPrice ?? old.avgBuyPrice,
    );
    state = [...state.sublist(0, idx), updated, ...state.sublist(idx + 1)];
    await _saveToPrefs();
  }

  Future<void> clearAlert(String symbol) async {
    final idx = state.indexWhere((s) => s.symbol == symbol);
    if (idx < 0) return;
    final old = state[idx];
    final updated = WatchlistStock(
      symbol: old.symbol, displayName: old.displayName,
      alertPrice: null, qty: old.qty, avgBuyPrice: old.avgBuyPrice);
    state = [...state.sublist(0, idx), updated, ...state.sublist(idx + 1)];
    await _saveToPrefs();
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<WatchlistStock>>(
  (ref) => WatchlistNotifier(),
);

// ── Refresh countdown ──
class RefreshCountdown extends StateNotifier<int> {
  Timer? _timer;
  final int _interval;
  final void Function()? onRefresh;

  RefreshCountdown(this._interval, {this.onRefresh}) : super(_interval) { _start(); }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state <= 1) { state = _interval; onRefresh?.call(); }
      else { state = state - 1; }
    });
  }

  void reset() { state = _interval; }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}

final refreshCountdownProvider = StateNotifierProvider<RefreshCountdown, int>(
  (ref) => RefreshCountdown(30, onRefresh: () {
    // ONLY refresh non-Gemini data (Yahoo Finance quotes).
    // Gemini-dependent providers (news, artha, IPO, weekly-brief) are
    // only refreshed on manual pull-to-refresh and hit backend cache.
    ref.invalidate(marketsOverviewProvider);
    ref.invalidate(marketsMoversProvider);
  }),
);
