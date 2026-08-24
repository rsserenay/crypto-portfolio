/// CoinGecko /coins/markets endpoint'inden dönen tek bir coin kaydını temsil eder.
class CoinModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;
  final double marketCap;

  CoinModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.marketCap,
  });

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    return CoinModel(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
    );
  }
  String get formattedMarketCap {
    if (marketCap >= 1000000000) {
      return '\$${(marketCap / 1000000000).toStringAsFixed(2)}B';
    }

    if (marketCap >= 1000000) {
      return '\$${(marketCap / 1000000).toStringAsFixed(2)}M';
    }

    if (marketCap >= 1000) {
      return '\$${(marketCap / 1000).toStringAsFixed(2)}K';
    }

    return '\$${marketCap.toStringAsFixed(0)}';
  }
}
