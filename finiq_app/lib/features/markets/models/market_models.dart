/// FinIQ Markets — Data models (10x Upgrade)
library;

class StockQuote {
  final String symbol;
  final String displayName;
  final double current;
  final double change;
  final double changePct;
  final double prevClose;
  final double high;
  final double low;
  final int volume;
  final List<double> sparkline;
  final bool isPositive;
  final String? error;
  // Extended fields (stock detail only)
  final double week52High;
  final double week52Low;
  final double? pe;
  final int? marketCap;
  final String? sector;

  StockQuote({
    required this.symbol, required this.displayName,
    required this.current, required this.change, required this.changePct,
    required this.prevClose, required this.high, required this.low,
    required this.volume, required this.sparkline, required this.isPositive,
    this.error, this.week52High = 0, this.week52Low = 0,
    this.pe, this.marketCap, this.sector,
  });

  factory StockQuote.fromJson(Map<String, dynamic> j) => StockQuote(
    symbol: j['symbol'] as String? ?? '',
    displayName: j['displayName'] as String? ?? j['symbol'] as String? ?? '',
    current: (j['current'] as num?)?.toDouble() ?? 0,
    change: (j['change'] as num?)?.toDouble() ?? 0,
    changePct: (j['changePct'] as num?)?.toDouble() ?? 0,
    prevClose: (j['prevClose'] as num?)?.toDouble() ?? 0,
    high: (j['high'] as num?)?.toDouble() ?? 0,
    low: (j['low'] as num?)?.toDouble() ?? 0,
    volume: (j['volume'] as num?)?.toInt() ?? 0,
    sparkline: (j['sparkline'] as List<dynamic>?)?.map((v) => (v as num).toDouble()).toList() ?? [],
    isPositive: j['isPositive'] as bool? ?? true,
    error: j['error'] as String?,
    week52High: (j['week52High'] as num?)?.toDouble() ?? 0,
    week52Low: (j['week52Low'] as num?)?.toDouble() ?? 0,
    pe: (j['pe'] as num?)?.toDouble(),
    marketCap: (j['marketCap'] as num?)?.toInt(),
    sector: j['sector'] as String?,
  );

  String get cleanSymbol => symbol.replaceAll('.NS', '').replaceAll('^', '');
}


class MarketOverview {
  final bool isMarketOpen;
  final String lastUpdated;
  final String sentiment;
  final Map<String, StockQuote> indices;
  final Map<String, StockQuote> sectors;
  final Map<String, StockQuote> global;

  MarketOverview({
    required this.isMarketOpen, required this.lastUpdated, required this.sentiment,
    required this.indices, required this.sectors, required this.global,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> j) {
    Map<String, StockQuote> parseMap(String key) {
      final raw = j[key] as Map<String, dynamic>? ?? {};
      return raw.map((k, v) => MapEntry(k, StockQuote.fromJson(v as Map<String, dynamic>)));
    }
    return MarketOverview(
      isMarketOpen: j['isMarketOpen'] as bool? ?? false,
      lastUpdated: j['lastUpdated'] as String? ?? '',
      sentiment: j['sentiment'] as String? ?? 'NEUTRAL',
      indices: parseMap('indices'),
      sectors: parseMap('sectors'),
      global: parseMap('global'),
    );
  }
}


class MarketMovers {
  final List<StockQuote> gainers;
  final List<StockQuote> losers;
  MarketMovers({required this.gainers, required this.losers});
  factory MarketMovers.fromJson(Map<String, dynamic> j) => MarketMovers(
    gainers: (j['gainers'] as List<dynamic>?)?.map((v) => StockQuote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
    losers: (j['losers'] as List<dynamic>?)?.map((v) => StockQuote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
  );
}


class ArthaMarketInsight {
  final String marketSummary;
  final String fireImpact;
  final String sipAdvice;
  final String sentiment;
  final String lastUpdated;
  final Map<String, String> sectorInsights;

  ArthaMarketInsight({
    required this.marketSummary, required this.fireImpact, required this.sipAdvice,
    required this.sentiment, required this.lastUpdated, required this.sectorInsights,
  });

  factory ArthaMarketInsight.fromJson(Map<String, dynamic> j) => ArthaMarketInsight(
    marketSummary: j['marketSummary'] as String? ?? '',
    fireImpact: j['fireImpact'] as String? ?? '',
    sipAdvice: j['sipAdvice'] as String? ?? '',
    sentiment: j['sentiment'] as String? ?? 'NEUTRAL',
    lastUpdated: j['lastUpdated'] as String? ?? '',
    sectorInsights: (j['sectorInsights'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {},
  );
}


class MarketNews {
  final String headline;
  final String source;
  final String timeAgo;
  final String sentiment;

  MarketNews({required this.headline, required this.source,
    required this.timeAgo, required this.sentiment});

  factory MarketNews.fromJson(Map<String, dynamic> j) => MarketNews(
    headline: j['headline'] as String? ?? '',
    source: j['source'] as String? ?? '',
    timeAgo: j['timeAgo'] as String? ?? '',
    sentiment: j['sentiment'] as String? ?? 'NEUTRAL',
  );
}


class WatchlistStock {
  final String symbol;
  final String displayName;
  StockQuote? quote;

  WatchlistStock({required this.symbol, required this.displayName, this.quote});
  Map<String, dynamic> toJson() => {'symbol': symbol, 'displayName': displayName};
  factory WatchlistStock.fromJson(Map<String, dynamic> j) => WatchlistStock(
    symbol: j['symbol'] as String? ?? '',
    displayName: j['displayName'] as String? ?? '',
  );
}

class SearchResult {
  final String displayName;
  final String symbol;
  SearchResult({required this.displayName, required this.symbol});
  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
    displayName: j['displayName'] as String? ?? '',
    symbol: j['symbol'] as String? ?? '',
  );
}
