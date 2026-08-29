import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/coin_model.dart';
import '../models/portfolio_holding.dart';
import 'market_controller.dart';

/// Cüzdanda görünecek tek satır:
/// coin bilgisi + miktar + güncel değer + kâr/zarar
class PortfolioItem {
  final CoinModel coin;
  final double amount;
  final double avgBuyPrice;

  double get valueUsd => coin.currentPrice * amount;

  double get investedUsd => avgBuyPrice * amount;

  double get profitUsd => valueUsd - investedUsd;

  double get profitPercentage {
    if (investedUsd <= 0) return 0.0;
    return (profitUsd / investedUsd) * 100;
  }

  PortfolioItem({
    required this.coin,
    required this.amount,
    required this.avgBuyPrice,
  });
}

/// Portföy ekranının tüm iş mantığı burada yaşar.
class PortfolioController extends GetxController {
  final GetStorage _box = GetStorage('portfolio_box');

  static const String _storageKey = 'portfolio_holdings';

  /// coinId -> sahip olunan miktar + ortalama alış fiyatı + işlem geçmişi
  final RxMap<String, PortfolioHolding> holdings =
      <String, PortfolioHolding>{}.obs;

  /// API'den gelen coinler.
  final RxMap<String, CoinModel> _priceMap = <String, CoinModel>{}.obs;

  /// View'in göstereceği portföy listesi.
  final RxList<PortfolioItem> portfolioItems = <PortfolioItem>[].obs;

  final MarketController _marketController = Get.find<MarketController>();

  final RxDouble totalBalanceUsd = 0.0.obs;
  final RxDouble totalProfitUsd = 0.0.obs;
  final RxDouble totalInvestedUsd = 0.0.obs;

  double get totalProfitPercentage {
    if (totalInvestedUsd.value <= 0) return 0.0;
    return (totalProfitUsd.value / totalInvestedUsd.value) * 100;
  }

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  late final Worker _priceWorker;

  @override
  void onInit() {
    super.onInit();

    _loadHoldingsFromStorage();

    _priceWorker = ever<List<CoinModel>>(
      _marketController.allCoins,
      (_) => _updatePricesFromMarket(),
    );

    _updatePricesFromMarket();
  }

  void _loadHoldingsFromStorage() {
    final Map<String, dynamic>? raw = _box.read(_storageKey);

    holdings.clear();

    if (raw != null) {
      raw.forEach((key, value) {
        if (value is Map) {
          holdings[key] = PortfolioHolding.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    _recomputePortfolio();
  }

  void _updatePricesFromMarket() {
    _priceMap.clear();

    for (final coin in _marketController.allCoins) {
      _priceMap[coin.id] = coin;
    }

    _recomputePortfolio();
  }

  Future<void> onPullToRefresh() async {
    isRefreshing.value = true;

    await _marketController.fetchCoins(silent: true);

    isRefreshing.value = false;
  }

  /// Coin satın alma.
  ///
  /// [inputAmount]: kullanıcının girdiği değer.
  /// [isCurrencyAmount] true ise [inputAmount] "kaç dolarlık/liralık"
  /// alınacağını ifade eder (örn: 200 -> 200$'lık coin) ve coin adedi
  /// güncel fiyata bölünerek hesaplanır. false ise [inputAmount]
  /// doğrudan coin adedidir (örn: 0.5 BTC).
  ///
  /// Yeni coin alındığında ortalama alış fiyatı:
  ///
  /// (Eski miktar × Eski ortalama fiyat
  ///  + Yeni miktar × Güncel fiyat)
  /// / Toplam miktar
  bool buyCoin(
    String coinId,
    double inputAmount, {
    bool isCurrencyAmount = false,
  }) {
    if (inputAmount <= 0) return false;

    final coin = _priceMap[coinId];

    // Fiyat henüz API'den gelmediyse satın alma yapılmaz.
    if (coin == null || coin.currentPrice <= 0) {
      return false;
    }

    // Kullanıcı "200 dolarlık coin al" dediyse coin adedine çeviriyoruz.
    final double amount =
        isCurrencyAmount ? (inputAmount / coin.currentPrice) : inputAmount;

    final CoinTransaction transaction = CoinTransaction(
      type: 'buy',
      amount: amount,
      price: coin.currentPrice,
      date: DateTime.now(),
    );

    final holding = holdings[coinId];

    if (holding == null) {
      holdings[coinId] = PortfolioHolding(
        amount: amount,
        avgBuyPrice: coin.currentPrice,
        transactions: [transaction],
      );
    } else {
      final oldAmount = holding.amount;
      final oldAvgPrice = holding.avgBuyPrice;
      final newAmount = oldAmount + amount;

      final newAvgBuyPrice =
          ((oldAmount * oldAvgPrice) + (amount * coin.currentPrice)) /
              newAmount;

      holdings[coinId] = PortfolioHolding(
        amount: newAmount,
        avgBuyPrice: newAvgBuyPrice,
        transactions: [...holding.transactions, transaction],
      );
    }

    _saveHoldings();
    _recomputePortfolio();

    return true;
  }

  /// Coin satışı.
  ///
  /// [isCurrencyAmount] true ise [inputAmount] "kaç dolarlık/liralık
  /// satmak istediğini" ifade eder.
  ///
  /// Satış yapıldığında ortalama alış fiyatı değişmez.
  /// Miktar sıfıra ulaşsa bile holding (ve işlem geçmişi) silinmez;
  /// sadece amount 0 olur. Böylece coin detayında geçmiş görünmeye devam eder.
  bool sellCoin(
    String coinId,
    double inputAmount, {
    bool isCurrencyAmount = false,
  }) {
    if (inputAmount <= 0) return false;

    final holding = holdings[coinId];

    if (holding == null) return false;

    final coin = _priceMap[coinId];
    final double sellPrice = coin?.currentPrice ?? holding.avgBuyPrice;

    final double amount =
        isCurrencyAmount ? (inputAmount / sellPrice) : inputAmount;

    final current = holding.amount;
    const double epsilon = 0.00000001;

    if (amount > current + epsilon) {
      return false;
    }

    final updatedAmount = current - amount;

    final CoinTransaction transaction = CoinTransaction(
      type: 'sell',
      amount: amount,
      price: sellPrice,
      date: DateTime.now(),
    );

    holdings[coinId] = PortfolioHolding(
      amount: updatedAmount <= epsilon ? 0 : updatedAmount,
      avgBuyPrice: holding.avgBuyPrice,
      transactions: [...holding.transactions, transaction],
    );

    _saveHoldings();
    _recomputePortfolio();

    return true;
  }

  /// Belirli bir coin için tüm işlem geçmişini (en yeni en üstte) döner.
  List<CoinTransaction> transactionsFor(String coinId) {
    final holding = holdings[coinId];
    if (holding == null) return [];
    return holding.transactions.reversed.toList();
  }

  /// GetStorage'a holdings verisini kaydeder.
  void _saveHoldings() {
    final Map<String, dynamic> toSave = {};

    holdings.forEach((key, value) {
      toSave[key] = value.toJson();
    });

    _box.write(_storageKey, toSave);
  }

  /// GetStorage'daki miktar + ortalama alış fiyatı
  /// ile API'deki güncel fiyatı birleştirir.
  void _recomputePortfolio() {
    final List<PortfolioItem> items = [];

    double total = 0.0;
    double totalInvested = 0.0;
    double totalProfit = 0.0;

    holdings.forEach((coinId, holding) {
      final coin = _priceMap[coinId];

      if (coin != null && holding.amount > 0) {
        final item = PortfolioItem(
          coin: coin,
          amount: holding.amount,
          avgBuyPrice: holding.avgBuyPrice,
        );

        items.add(item);

        total += item.valueUsd;
        totalInvested += item.investedUsd;
        totalProfit += item.profitUsd;
      }
    });

    items.sort(
      (a, b) => b.valueUsd.compareTo(a.valueUsd),
    );

    portfolioItems.assignAll(items);

    totalBalanceUsd.value = total;
    totalInvestedUsd.value = totalInvested;
    totalProfitUsd.value = totalProfit;
  }

  /// Coini işlem geçmişiyle birlikte tamamen siler (satış değil, sıfırlama).
  void deleteCoin(String coinId) {
    holdings.remove(coinId);

    _saveHoldings();
    _recomputePortfolio();
  }

  @override
  void onClose() {
    _priceWorker.dispose();
    super.onClose();
  }
}