/// Smart Buy Lens data models — production grade.
/// Handles single analysis, comparison, and online search results.

class QualityBreakdown {
  final String brandReputation;
  final String buildOrIngredients;
  final String packaging;
  final List<String> redFlags;

  const QualityBreakdown({
    this.brandReputation = 'UNKNOWN',
    this.buildOrIngredients = '',
    this.packaging = 'STANDARD',
    this.redFlags = const [],
  });

  factory QualityBreakdown.fromJson(Map<String, dynamic> json) {
    return QualityBreakdown(
      brandReputation: json['brandReputation'] as String? ?? 'UNKNOWN',
      buildOrIngredients: json['buildOrIngredients'] as String? ?? '',
      packaging: json['packaging'] as String? ?? 'STANDARD',
      redFlags: (json['redFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'brandReputation': brandReputation,
        'buildOrIngredients': buildOrIngredients,
        'packaging': packaging,
        'redFlags': redFlags,
      };
}

class KeySpec {
  final String label;
  final String value;

  const KeySpec({required this.label, required this.value});

  factory KeySpec.fromJson(Map<String, dynamic> json) {
    return KeySpec(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class Alternative {
  final String name;
  final String priceRange;
  final String reason;

  const Alternative({
    required this.name,
    required this.priceRange,
    required this.reason,
  });

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      name: json['name'] as String? ?? '',
      priceRange: json['priceRange'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ONLINE SEARCH MODELS
// ═══════════════════════════════════════════════════════════

class OnlineListing {
  final String platform;
  final String url;
  final double? price;
  final double? originalPrice;
  final String? discount;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String? badge;

  const OnlineListing({
    required this.platform,
    required this.url,
    this.price,
    this.originalPrice,
    this.discount,
    this.rating = 0,
    this.reviewCount = 0,
    this.inStock = true,
    this.badge,
  });

  factory OnlineListing.fromJson(Map<String, dynamic> json) {
    return OnlineListing(
      platform: json['platform'] as String? ?? 'Unknown',
      url: json['url'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discount: json['discount'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      inStock: json['inStock'] as bool? ?? true,
      badge: json['badge'] as String?,
    );
  }
}

class PriceHistory {
  final bool isGoodDeal;
  final String dealReason;
  final double? lowestEver;

  const PriceHistory({
    this.isGoodDeal = false,
    this.dealReason = '',
    this.lowestEver,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      isGoodDeal: json['isGoodDeal'] as bool? ?? false,
      dealReason: json['dealReason'] as String? ?? '',
      lowestEver: (json['lowestEver'] as num?)?.toDouble(),
    );
  }
}

class SimilarProduct {
  final String name;
  final String brand;
  final double price;
  final String url;
  final String platform;
  final String whyConsider;
  final double rating;

  const SimilarProduct({
    required this.name,
    required this.brand,
    required this.price,
    required this.url,
    required this.platform,
    required this.whyConsider,
    this.rating = 0,
  });

  factory SimilarProduct.fromJson(Map<String, dynamic> json) {
    return SimilarProduct(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      url: json['url'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      whyConsider: json['whyConsider'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SINGLE PRODUCT RESULT
// ═══════════════════════════════════════════════════════════

class SingleProductResult {
  final String productName;
  final String brand;
  final String category;
  final double? detectedPrice;
  final String verdict;
  final String verdictReason;
  final String affordabilityLevel;
  final double affordabilityPercent;
  final double valueForMoneyScore;
  final double qualityScore;
  final QualityBreakdown qualityBreakdown;
  final List<KeySpec> keySpecs;
  final List<String> pros;
  final List<String> cons;
  final String arthaInsight;
  final List<Alternative> alternatives;
  final String imageHash;
  // Online search
  final List<OnlineListing> onlineListings;
  final PriceHistory priceHistory;
  final List<SimilarProduct> similarProducts;
  // Corruption flag
  final bool profileDataCorrupted;

  const SingleProductResult({
    required this.productName,
    required this.brand,
    required this.category,
    this.detectedPrice,
    required this.verdict,
    required this.verdictReason,
    required this.affordabilityLevel,
    required this.affordabilityPercent,
    required this.valueForMoneyScore,
    required this.qualityScore,
    required this.qualityBreakdown,
    required this.keySpecs,
    required this.pros,
    required this.cons,
    required this.arthaInsight,
    required this.alternatives,
    this.imageHash = '',
    this.onlineListings = const [],
    this.priceHistory = const PriceHistory(),
    this.similarProducts = const [],
    this.profileDataCorrupted = false,
  });

  factory SingleProductResult.fromJson(Map<String, dynamic> json,
      {String imageHash = '', bool profileCorrupted = false}) {
    return SingleProductResult(
      productName: json['productName'] as String? ?? 'Unknown Product',
      brand: json['brand'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'OTHER',
      detectedPrice: (json['detectedPrice'] as num?)?.toDouble(),
      verdict: json['verdict'] as String? ?? 'CONSIDER',
      verdictReason: json['verdictReason'] as String? ?? '',
      affordabilityLevel: json['affordabilityLevel'] as String? ?? 'MANAGEABLE',
      affordabilityPercent: (json['affordabilityPercent'] as num?)?.toDouble() ?? 0,
      valueForMoneyScore: (json['valueForMoneyScore'] as num?)?.toDouble() ?? 5,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 5,
      qualityBreakdown: json['qualityBreakdown'] != null
          ? QualityBreakdown.fromJson(json['qualityBreakdown'] as Map<String, dynamic>)
          : const QualityBreakdown(),
      keySpecs: (json['keySpecs'] as List<dynamic>?)
              ?.map((e) => KeySpec.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pros: (json['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cons: (json['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      arthaInsight: json['arthaInsight'] as String? ?? '',
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => Alternative.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      imageHash: imageHash,
      onlineListings: (json['onlineListings'] as List<dynamic>?)
              ?.map((e) => OnlineListing.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priceHistory: json['priceHistory'] != null
          ? PriceHistory.fromJson(json['priceHistory'] as Map<String, dynamic>)
          : const PriceHistory(),
      similarProducts: (json['similarProducts'] as List<dynamic>?)
              ?.map((e) => SimilarProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      profileDataCorrupted: profileCorrupted,
    );
  }

  bool get isUnrecognised => productName == 'Unknown' || productName == 'Unknown Product';

  Map<String, dynamic> toReportJson() => {
        'name': productName,
        'brand': brand,
        'category': category,
        'detectedPrice': detectedPrice,
        'imageHash': imageHash,
        'scores': {
          'overall': qualityScore,
          'valueForMoney': valueForMoneyScore,
        },
        'verdict': verdict,
        'affordabilityLevel': affordabilityLevel,
        'affordabilityPercent': affordabilityPercent,
        'pros': pros,
        'cons': cons,
        'arthaInsight': arthaInsight,
      };
}

// ═══════════════════════════════════════════════════════════
// COMPARISON MODELS
// ═══════════════════════════════════════════════════════════

class ProductScores {
  final double valueForMoney;
  final double buildQuality;
  final double brandTrust;
  final double featuresScore;
  final double longTermWorth;
  final double overall;

  const ProductScores({
    this.valueForMoney = 5,
    this.buildQuality = 5,
    this.brandTrust = 5,
    this.featuresScore = 5,
    this.longTermWorth = 5,
    this.overall = 5,
  });

  factory ProductScores.fromJson(Map<String, dynamic> json) {
    return ProductScores(
      valueForMoney: (json['valueForMoney'] as num?)?.toDouble() ?? 5,
      buildQuality: (json['buildQuality'] as num?)?.toDouble() ?? 5,
      brandTrust: (json['brandTrust'] as num?)?.toDouble() ?? 5,
      featuresScore: (json['featuresScore'] as num?)?.toDouble() ?? 5,
      longTermWorth: (json['longTermWorth'] as num?)?.toDouble() ?? 5,
      overall: (json['overall'] as num?)?.toDouble() ?? 5,
    );
  }
}

class ComparedProduct {
  final String name;
  final String brand;
  final double? detectedPrice;
  final ProductScores scores;
  final List<String> pros;
  final List<String> cons;
  final String affordabilityLevel;
  // Online data for winner
  final List<OnlineListing> onlineListings;

  const ComparedProduct({
    required this.name,
    required this.brand,
    this.detectedPrice,
    required this.scores,
    required this.pros,
    required this.cons,
    required this.affordabilityLevel,
    this.onlineListings = const [],
  });

  factory ComparedProduct.fromJson(Map<String, dynamic> json) {
    return ComparedProduct(
      name: json['name'] as String? ?? 'Unknown',
      brand: json['brand'] as String? ?? 'Unknown',
      detectedPrice: (json['detectedPrice'] as num?)?.toDouble(),
      scores: json['scores'] != null
          ? ProductScores.fromJson(json['scores'] as Map<String, dynamic>)
          : const ProductScores(),
      pros: (json['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cons: (json['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      affordabilityLevel: json['affordabilityLevel'] as String? ?? 'MANAGEABLE',
      onlineListings: (json['onlineListings'] as List<dynamic>?)
              ?.map((e) => OnlineListing.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toReportJson() => {
        'name': name,
        'brand': brand,
        'detectedPrice': detectedPrice,
        'scores': {
          'overall': scores.overall,
          'valueForMoney': scores.valueForMoney,
          'buildQuality': scores.buildQuality,
          'brandTrust': scores.brandTrust,
          'featuresScore': scores.featuresScore,
          'longTermWorth': scores.longTermWorth,
        },
        'affordabilityLevel': affordabilityLevel,
        'pros': pros,
        'cons': cons,
      };
}

class ComparisonRow {
  final String attribute;
  final String product1Value;
  final String product2Value;
  final int winner;

  const ComparisonRow({
    required this.attribute,
    required this.product1Value,
    required this.product2Value,
    required this.winner,
  });

  factory ComparisonRow.fromJson(Map<String, dynamic> json) {
    return ComparisonRow(
      attribute: json['attribute'] as String? ?? '',
      product1Value: json['product1Value'] as String? ?? '-',
      product2Value: json['product2Value'] as String? ?? '-',
      winner: (json['winner'] as num?)?.toInt() ?? 0,
    );
  }
}

class CompareProductResult {
  final String category;
  final ComparedProduct product1;
  final ComparedProduct product2;
  final List<ComparisonRow> comparisonTable;
  final int winner;
  final String winnerReason;
  final String arthaInsight;
  final bool bothAffordable;
  final String imageHash1;
  final String imageHash2;
  final bool profileDataCorrupted;

  const CompareProductResult({
    required this.category,
    required this.product1,
    required this.product2,
    required this.comparisonTable,
    required this.winner,
    required this.winnerReason,
    required this.arthaInsight,
    required this.bothAffordable,
    this.imageHash1 = '',
    this.imageHash2 = '',
    this.profileDataCorrupted = false,
  });

  factory CompareProductResult.fromJson(Map<String, dynamic> json,
      {String imageHash1 = '', String imageHash2 = '', bool profileCorrupted = false}) {
    return CompareProductResult(
      category: json['category'] as String? ?? 'OTHER',
      product1: ComparedProduct.fromJson(json['product1'] as Map<String, dynamic>? ?? {}),
      product2: ComparedProduct.fromJson(json['product2'] as Map<String, dynamic>? ?? {}),
      comparisonTable: (json['comparisonTable'] as List<dynamic>?)
              ?.map((e) => ComparisonRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      winner: (json['winner'] as num?)?.toInt() ?? 1,
      winnerReason: json['winnerReason'] as String? ?? '',
      arthaInsight: json['arthaInsight'] as String? ?? '',
      bothAffordable: json['bothAffordable'] as bool? ?? false,
      imageHash1: imageHash1,
      imageHash2: imageHash2,
      profileDataCorrupted: profileCorrupted,
    );
  }

  ComparedProduct get winnerProduct => winner == 1 ? product1 : product2;
  ComparedProduct get loserProduct => winner == 1 ? product2 : product1;
}
