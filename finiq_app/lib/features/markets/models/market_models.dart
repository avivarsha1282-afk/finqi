/// FinIQ Markets — Data models (Phase 3 Rebuild)
library;

// ═══════════════════════════════════════════════════════════
// Symbol display name mapping (BUG 1 fix)
// ═══════════════════════════════════════════════════════════

const Map<String, String> kSymbolDisplayNames = {
  '^NSEI':      'Nifty 50',
  '^BSESN':     'Sensex',
  '^NSEBANK':   'Bank Nifty',
  '^CNXIT':     'Nifty IT',
  '^NSEMDCP50': 'Nifty Mid Cap',
  '^GSPC':      'S&P 500',
  '^IXIC':      'Nasdaq',
  '^N225':      'Nikkei 225',
  '^HSI':       'Hang Seng',
  '^FTSE':      'FTSE 100',
  '^CNXAUTO':   'Nifty Auto',
  '^CNXFMCG':   'Nifty FMCG',
  '^CNXPHARMA': 'Nifty Pharma',
  '^CNXMETAL':  'Nifty Metal',
  '^CNXREALTY': 'Nifty Realty',
  '^CNXENERGY': 'Nifty Energy',
};

String getDisplayName(String symbol, String fallback) =>
    kSymbolDisplayNames[symbol] ?? fallback;

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
  // Volume shockers
  final int? todayVolume;
  final int? avgVolume;
  final double? volumeRatio;

  StockQuote({
    required this.symbol, required this.displayName,
    required this.current, required this.change, required this.changePct,
    required this.prevClose, required this.high, required this.low,
    required this.volume, required this.sparkline, required this.isPositive,
    this.error, this.week52High = 0, this.week52Low = 0,
    this.pe, this.marketCap, this.sector,
    this.todayVolume, this.avgVolume, this.volumeRatio,
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
    todayVolume: (j['todayVolume'] as num?)?.toInt(),
    avgVolume: (j['avgVolume'] as num?)?.toInt(),
    volumeRatio: (j['volumeRatio'] as num?)?.toDouble(),
  );

  String get cleanSymbol => symbol.replaceAll('.NS', '').replaceAll('.BO', '').replaceAll('^', '');
}


// ═══════════════════════════════════════════════════════════
// Chart data
// ═══════════════════════════════════════════════════════════

class ChartCandle {
  final String timestamp;
  final double open, high, low, close;
  final int volume;

  ChartCandle({
    required this.timestamp, required this.open, required this.high,
    required this.low, required this.close, required this.volume,
  });

  factory ChartCandle.fromJson(Map<String, dynamic> j) => ChartCandle(
    timestamp: j['timestamp'] as String? ?? '',
    open: (j['open'] as num?)?.toDouble() ?? 0,
    high: (j['high'] as num?)?.toDouble() ?? 0,
    low: (j['low'] as num?)?.toDouble() ?? 0,
    close: (j['close'] as num?)?.toDouble() ?? 0,
    volume: (j['volume'] as num?)?.toInt() ?? 0,
  );
}

class ChartData {
  final String symbol;
  final String period;
  final List<ChartCandle> candles;
  final double firstClose;
  final double lastClose;

  ChartData({
    required this.symbol, required this.period, required this.candles,
    required this.firstClose, required this.lastClose,
  });

  factory ChartData.fromJson(Map<String, dynamic> j) => ChartData(
    symbol: j['symbol'] as String? ?? '',
    period: j['period'] as String? ?? '1d',
    candles: (j['candles'] as List<dynamic>?)
        ?.map((v) => ChartCandle.fromJson(v as Map<String, dynamic>)).toList() ?? [],
    firstClose: (j['firstClose'] as num?)?.toDouble() ?? 0,
    lastClose: (j['lastClose'] as num?)?.toDouble() ?? 0,
  );

  bool get isPositive => lastClose >= firstClose;
  double get change => lastClose - firstClose;
  double get changePct => firstClose > 0 ? (change / firstClose * 100) : 0;
}


// ═══════════════════════════════════════════════════════════
// Commodity quote
// ═══════════════════════════════════════════════════════════

class CommodityQuote {
  final String displayName;
  final String symbol;
  final double current;      // USD price
  final double priceINR;     // converted to INR
  final String unit;         // "per 10g · 24K", "per kg", "per barrel"
  final double changePct;
  final bool isPositive;

  CommodityQuote({
    required this.displayName, required this.symbol, required this.current,
    required this.priceINR, required this.unit, required this.changePct,
    required this.isPositive,
  });

  factory CommodityQuote.fromJson(Map<String, dynamic> j) => CommodityQuote(
    displayName: j['displayName'] as String? ?? '',
    symbol: j['symbol'] as String? ?? '',
    current: (j['current'] as num?)?.toDouble() ?? 0,
    priceINR: (j['priceINR'] as num?)?.toDouble() ?? 0,
    unit: j['unit'] as String? ?? '',
    changePct: (j['changePct'] as num?)?.toDouble() ?? 0,
    isPositive: j['isPositive'] as bool? ?? true,
  );
}


// ═══════════════════════════════════════════════════════════
// Market overview (with commodities)
// ═══════════════════════════════════════════════════════════

class MarketOverview {
  final bool isMarketOpen;
  final String lastUpdated;
  final String sentiment;
  final Map<String, StockQuote> indices;
  final Map<String, StockQuote> sectors;
  final Map<String, StockQuote> global;
  final Map<String, CommodityQuote> commodities;

  MarketOverview({
    required this.isMarketOpen, required this.lastUpdated, required this.sentiment,
    required this.indices, required this.sectors, required this.global,
    required this.commodities,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> j) {
    Map<String, StockQuote> parseMap(String key) {
      final raw = j[key] as Map<String, dynamic>? ?? {};
      return raw.map((k, v) => MapEntry(k, StockQuote.fromJson(v as Map<String, dynamic>)));
    }
    Map<String, CommodityQuote> parseCommodities() {
      final raw = j['commodities'] as Map<String, dynamic>? ?? {};
      return raw.map((k, v) => MapEntry(k, CommodityQuote.fromJson(v as Map<String, dynamic>)));
    }
    return MarketOverview(
      isMarketOpen: j['isMarketOpen'] as bool? ?? false,
      lastUpdated: j['lastUpdated'] as String? ?? '',
      sentiment: j['sentiment'] as String? ?? 'NEUTRAL',
      indices: parseMap('indices'),
      sectors: parseMap('sectors'),
      global: parseMap('global'),
      commodities: parseCommodities(),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// Market movers (with volume shockers)
// ═══════════════════════════════════════════════════════════

class MarketMovers {
  final List<StockQuote> gainers;
  final List<StockQuote> losers;
  final List<StockQuote> volumeShockers;

  MarketMovers({required this.gainers, required this.losers, required this.volumeShockers});

  factory MarketMovers.fromJson(Map<String, dynamic> j) => MarketMovers(
    gainers: (j['gainers'] as List<dynamic>?)?.map((v) => StockQuote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
    losers: (j['losers'] as List<dynamic>?)?.map((v) => StockQuote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
    volumeShockers: (j['volumeShockers'] as List<dynamic>?)?.map((v) => StockQuote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
  );
}


// ═══════════════════════════════════════════════════════════
// Artha market insight (with FII/DII)
// ═══════════════════════════════════════════════════════════

class ArthaMarketInsight {
  final String marketSummary;
  final String fireImpact;
  final String sipAdvice;
  final String sentiment;
  final String lastUpdated;
  final Map<String, String> sectorInsights;
  final double? fiiNet;
  final double? diiNet;
  final String? fiiDiiSource;

  ArthaMarketInsight({
    required this.marketSummary, required this.fireImpact, required this.sipAdvice,
    required this.sentiment, required this.lastUpdated, required this.sectorInsights,
    this.fiiNet, this.diiNet, this.fiiDiiSource,
  });

  factory ArthaMarketInsight.fromJson(Map<String, dynamic> j) => ArthaMarketInsight(
    marketSummary: j['marketSummary'] as String? ?? '',
    fireImpact: j['fireImpact'] as String? ?? '',
    sipAdvice: j['sipAdvice'] as String? ?? '',
    sentiment: j['sentiment'] as String? ?? 'NEUTRAL',
    lastUpdated: j['lastUpdated'] as String? ?? '',
    sectorInsights: (j['sectorInsights'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {},
    fiiNet: (j['fiiNet'] as num?)?.toDouble(),
    diiNet: (j['diiNet'] as num?)?.toDouble(),
    fiiDiiSource: j['fiiDiiSource'] as String?,
  );
}


// ═══════════════════════════════════════════════════════════
// Market news
// ═══════════════════════════════════════════════════════════

class MarketNews {
  final String headline;
  final String source;
  final String timeAgo;
  final String sentiment;
  final String url;

  MarketNews({required this.headline, required this.source,
    required this.timeAgo, required this.sentiment, this.url = ''});

  factory MarketNews.fromJson(Map<String, dynamic> j) => MarketNews(
    headline: j['headline'] as String? ?? '',
    source: j['source'] as String? ?? '',
    timeAgo: j['timeAgo'] as String? ?? '',
    sentiment: j['sentiment'] as String? ?? 'NEUTRAL',
    url: j['url'] as String? ?? '',
  );
}


// ═══════════════════════════════════════════════════════════
// IPO models
// ═══════════════════════════════════════════════════════════

class UpcomingIPO {
  final String companyName;
  final String priceRange;
  final String openDate;
  final String closeDate;
  final int? lotSize;
  final int? minInvestment;
  final String category;
  final double? gmp;
  final double? gmpPct;

  UpcomingIPO({
    required this.companyName, required this.priceRange,
    required this.openDate, required this.closeDate,
    this.lotSize, this.minInvestment, required this.category,
    this.gmp, this.gmpPct,
  });

  factory UpcomingIPO.fromJson(Map<String, dynamic> j) => UpcomingIPO(
    companyName: j['companyName'] as String? ?? '',
    priceRange: j['priceRange'] as String? ?? '',
    openDate: j['openDate'] as String? ?? '',
    closeDate: j['closeDate'] as String? ?? '',
    lotSize: (j['lotSize'] as num?)?.toInt(),
    minInvestment: (j['minInvestment'] as num?)?.toInt(),
    category: j['category'] as String? ?? 'Mainboard',
    gmp: (j['gmp'] as num?)?.toDouble(),
    gmpPct: (j['gmpPct'] as num?)?.toDouble(),
  );
}

class RecentIPO {
  final String companyName;
  final double issuePrice;
  final double listingPrice;
  final double currentPrice;
  final double listingGain;
  final String listingDate;

  RecentIPO({
    required this.companyName, required this.issuePrice,
    required this.listingPrice, required this.currentPrice,
    required this.listingGain, required this.listingDate,
  });

  factory RecentIPO.fromJson(Map<String, dynamic> j) => RecentIPO(
    companyName: j['companyName'] as String? ?? '',
    issuePrice: (j['issuePrice'] as num?)?.toDouble() ?? 0,
    listingPrice: (j['listingPrice'] as num?)?.toDouble() ?? 0,
    currentPrice: (j['currentPrice'] as num?)?.toDouble() ?? 0,
    listingGain: (j['listingGain'] as num?)?.toDouble() ?? 0,
    listingDate: j['listingDate'] as String? ?? '',
  );
}

class IPOData {
  final List<UpcomingIPO> upcoming;
  final List<RecentIPO> recentListings;

  IPOData({required this.upcoming, required this.recentListings});

  factory IPOData.fromJson(Map<String, dynamic> j) => IPOData(
    upcoming: (j['upcoming'] as List<dynamic>?)
        ?.map((v) => UpcomingIPO.fromJson(v as Map<String, dynamic>)).toList() ?? [],
    recentListings: (j['recentListings'] as List<dynamic>?)
        ?.map((v) => RecentIPO.fromJson(v as Map<String, dynamic>)).toList() ?? [],
  );
}


// ═══════════════════════════════════════════════════════════
// Watchlist
// ═══════════════════════════════════════════════════════════

class WatchlistStock {
  final String symbol;
  final String displayName;
  final double? alertPrice;
  final int? qty;
  final double? avgBuyPrice;
  StockQuote? quote;

  WatchlistStock({
    required this.symbol, required this.displayName, this.quote,
    this.alertPrice, this.qty, this.avgBuyPrice,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol, 'displayName': displayName,
    if (alertPrice != null) 'alertPrice': alertPrice,
    if (qty != null) 'qty': qty,
    if (avgBuyPrice != null) 'avgBuyPrice': avgBuyPrice,
  };

  factory WatchlistStock.fromJson(Map<String, dynamic> j) => WatchlistStock(
    symbol: j['symbol'] as String? ?? '',
    displayName: j['displayName'] as String? ?? '',
    alertPrice: (j['alertPrice'] as num?)?.toDouble(),
    qty: (j['qty'] as num?)?.toInt(),
    avgBuyPrice: (j['avgBuyPrice'] as num?)?.toDouble(),
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

class WeeklyBrief {
  final String content;
  final String headline;
  final String niftyChange;
  final String weekLabel;
  final String topSector;
  final String keyEvent;
  final String weekAhead;
  final double? niftyWeekChange;
  final String mood;
  final bool available;

  WeeklyBrief({
    required this.content,
    required this.headline,
    required this.niftyChange,
    required this.weekLabel,
    required this.topSector,
    required this.keyEvent,
    required this.weekAhead,
    this.niftyWeekChange,
    this.mood = 'SIDEWAYS',
    this.available = false,
  });

  factory WeeklyBrief.fromJson(Map<String, dynamic> j) => WeeklyBrief(
    content: j['content'] as String? ?? '',
    headline: j['headline'] as String? ?? j['content'] as String? ?? '',
    niftyChange: j['niftyChange'] as String? ?? '',
    weekLabel: j['weekLabel'] as String? ?? '',
    topSector: j['topSector'] as String? ?? '',
    keyEvent: j['keyEvent'] as String? ?? '',
    weekAhead: j['weekAhead'] as String? ?? '',
    niftyWeekChange: (j['niftyWeekChange'] as num?)?.toDouble(),
    mood: j['mood'] as String? ?? 'SIDEWAYS',
    available: j['available'] as bool? ?? false,
  );
}
