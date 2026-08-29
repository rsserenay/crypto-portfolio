/// CoinGecko /global endpoint'inden dönen piyasa geneli özet verisi.
/// Market ekranının en üstündeki özet şeritte gösterilir.
class GlobalMarketData {
  final double totalMarketCapUsd;
  final double totalVolumeUsd;
  final double btcDominancePct;
  final double marketCapChangePercentage24h;

  const GlobalMarketData({
    required this.totalMarketCapUsd,
    required this.totalVolumeUsd,
    required this.btcDominancePct,
    required this.marketCapChangePercentage24h,
  });

  factory GlobalMarketData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    final totalMarketCap = data['total_market_cap'] as Map<String, dynamic>?;
    final totalVolume = data['total_volume'] as Map<String, dynamic>?;
    final btcDominance = data['market_cap_percentage'] as Map<String, dynamic>?;

    return GlobalMarketData(
      totalMarketCapUsd:
          ((totalMarketCap?['usd'] ?? 0) as num).toDouble(),
      totalVolumeUsd: ((totalVolume?['usd'] ?? 0) as num).toDouble(),
      btcDominancePct: ((btcDominance?['btc'] ?? 0) as num).toDouble(),
      marketCapChangePercentage24h:
          ((data['market_cap_change_percentage_24h_usd'] ?? 0) as num)
              .toDouble(),
    );
  }

  static String formatCompact(double value) {
    if (value >= 1000000000000) {
      return '\$${(value / 1000000000000).toStringAsFixed(2)}T';
    }
    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}

/// CoinGecko /coins/markets endpoint'inden dönen tek bir coin kaydını temsil eder.
class CoinModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;
  final double marketCap;
  final double high24h;
  final double low24h;
  final double totalVolume;

  /// Son 7 günün fiyat verisi (mini sparkline grafik için).
  /// API `sparkline=true` ile istendiğinde dolu gelir.
  final List<double> sparklineData;

  CoinModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.marketCap,
    this.high24h = 0,
    this.low24h = 0,
    this.totalVolume = 0,
    this.sparklineData = const [],
  });

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    List<double> sparkline = const [];
    final sparklineJson = json['sparkline_in_7d'];
    if (sparklineJson is Map && sparklineJson['price'] is List) {
      sparkline = (sparklineJson['price'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return CoinModel(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      high24h: (json['high_24h'] ?? 0).toDouble(),
      low24h: (json['low_24h'] ?? 0).toDouble(),
      totalVolume: (json['total_volume'] ?? 0).toDouble(),
      sparklineData: sparkline,
    );
  }

  String get formattedMarketCap => _formatCompact(marketCap);

  String get formattedVolume => _formatCompact(totalVolume);

  static String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}

/// CoinGecko /coins/{id}/ohlc endpoint'inden dönen tek bir mum (candle).
class CandleModel {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleModel({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  /// API her mumu [timestamp, open, high, low, close] dizisi olarak döner.
  factory CandleModel.fromList(List<dynamic> raw) {
    return CandleModel(
      time: DateTime.fromMillisecondsSinceEpoch(raw[0] as int),
      open: (raw[1] as num).toDouble(),
      high: (raw[2] as num).toDouble(),
      low: (raw[3] as num).toDouble(),
      close: (raw[4] as num).toDouble(),
    );
  }

  bool get isBullish => close >= open;
}