/// Tek bir alım/satım işlemini temsil eder.
/// "O tarihte ne kadar paraya ne almışız" bilgisini burada saklıyoruz.
class CoinTransaction {
  final String type; // 'buy' | 'sell'
  final double amount; // coin adedi
  final double price; // işlem anındaki birim fiyat
  final DateTime date;

  const CoinTransaction({
    required this.type,
    required this.amount,
    required this.price,
    required this.date,
  });

  bool get isBuy => type == 'buy';

  /// İşlemin toplam parasal değeri (adet x fiyat).
  double get totalValue => amount * price;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'price': price,
      'date': date.toIso8601String(),
    };
  }

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      type: json['type'] as String? ?? 'buy',
      amount: (json['amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PortfolioHolding {
  final double amount;
  final double avgBuyPrice;

  /// Bu coin için yapılmış tüm alım/satım işlemlerinin geçmişi.
  /// Coin tamamen satılsa bile (amount 0 olsa bile) bu liste silinmez;
  /// böylece kullanıcı geçmişte ne zaman ne aldığını görebilir.
  final List<CoinTransaction> transactions;

  PortfolioHolding({
    required this.amount,
    required this.avgBuyPrice,
    this.transactions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'avgBuyPrice': avgBuyPrice,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTx = (json['transactions'] as List<dynamic>?) ?? [];

    return PortfolioHolding(
      amount: (json['amount'] as num).toDouble(),
      avgBuyPrice: (json['avgBuyPrice'] as num).toDouble(),
      transactions: rawTx
          .map((e) => CoinTransaction.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}