class PortfolioHolding {
  final double amount;
  final double avgBuyPrice;

  PortfolioHolding({
    required this.amount,
    required this.avgBuyPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'avgBuyPrice': avgBuyPrice,
    };
  }

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      amount: (json['amount'] as num).toDouble(),
      avgBuyPrice: (json['avgBuyPrice'] as num).toDouble(),
    );
  }
}