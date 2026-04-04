import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../models/market_models.dart';

/// Service for all /api/markets/* HTTP calls
class MarketsService {
  MarketsService._();
  static final instance = MarketsService._();

  Future<MarketOverview> getOverview() async {
    try {
      final res = await ApiService.instance.getData('/markets/overview');
      return MarketOverview.fromJson(res);
    } catch (e) {
      debugPrint('[MarketsService] overview error: $e');
      rethrow;
    }
  }

  Future<MarketMovers> getMovers() async {
    try {
      final res = await ApiService.instance.getData('/markets/movers');
      return MarketMovers.fromJson(res);
    } catch (e) {
      debugPrint('[MarketsService] movers error: $e');
      rethrow;
    }
  }

  Future<Map<String, StockQuote>> getWatchlistQuotes(List<String> symbols) async {
    try {
      final res = await ApiService.instance.postData('/markets/watchlist-quotes', {'symbols': symbols});
      final quotesRaw = res['quotes'] as Map<String, dynamic>? ?? {};
      return quotesRaw.map((k, v) => MapEntry(k, StockQuote.fromJson(v as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('[MarketsService] watchlist-quotes error: $e');
      rethrow;
    }
  }

  Future<List<SearchResult>> searchStocks(String query) async {
    try {
      final res = await ApiService.instance.getData('/markets/search?q=$query');
      final list = res['results'] as List<dynamic>? ?? [];
      return list.map((v) => SearchResult.fromJson(v as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[MarketsService] search error: $e');
      rethrow;
    }
  }

  Future<ArthaMarketInsight> getArthaInsight({
    double fireCorpus = 0, double monthlySip = 0, String riskAppetite = 'moderate',
  }) async {
    try {
      final q = 'fire_corpus=$fireCorpus&monthly_sip=$monthlySip&risk_appetite=$riskAppetite';
      final res = await ApiService.instance.getData('/markets/artha-insight?$q');
      return ArthaMarketInsight.fromJson(res);
    } catch (e) {
      debugPrint('[MarketsService] artha-insight error: $e');
      rethrow;
    }
  }

  Future<List<MarketNews>> getNews() async {
    try {
      final res = await ApiService.instance.getData('/markets/news');
      final list = res['news'] as List<dynamic>? ?? [];
      return list.map((v) => MarketNews.fromJson(v as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[MarketsService] news error: $e');
      rethrow;
    }
  }

  Future<List<StockQuote>> getSectorStocks(String sectorName) async {
    try {
      final res = await ApiService.instance.getData('/markets/sector/$sectorName');
      final list = res['stocks'] as List<dynamic>? ?? [];
      return list.map((v) => StockQuote.fromJson(v as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[MarketsService] sector stocks error: $e');
      rethrow;
    }
  }

  Future<StockQuote> getStockDetail(String symbol) async {
    try {
      final res = await ApiService.instance.getData('/markets/stock-detail?symbol=$symbol');
      return StockQuote.fromJson(res);
    } catch (e) {
      debugPrint('[MarketsService] stock-detail error: $e');
      rethrow;
    }
  }
}
