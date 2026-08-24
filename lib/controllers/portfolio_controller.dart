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

  /// coinId -> sahip olunan miktar + ortalama alış fiyatı
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

  @override
  void onInit() {
    super.onInit();

    _loadHoldingsFromStorage();

    ever<List<CoinModel>>(
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
  /// Yeni coin alındığında ortalama alış fiyatı:
  ///
  /// (Eski miktar × Eski ortalama fiyat
  ///  + Yeni miktar × Güncel fiyat)
  /// / Toplam miktar
  void buyCoin(String coinId, double amount) {
    if (amount <= 0) return;

    final coin = _priceMap[coinId];

    if (coin == null) {
      Get.snackbar(
        'Hata',
        'Coin fiyat bilgisi bulunamadı.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final current = holdings[coinId];

    if (current == null) {
      holdings[coinId] = PortfolioHolding(
        amount: amount,
        avgBuyPrice: coin.currentPrice,
      );
    } else {
      final oldAmount = current.amount;
      final oldAvgPrice = current.avgBuyPrice;

      final newAmount = oldAmount + amount;

      final newAvgBuyPrice =
          ((oldAmount * oldAvgPrice) + (amount * coin.currentPrice)) /
              newAmount;

      holdings[coinId] = PortfolioHolding(
        amount: newAmount,
        avgBuyPrice: newAvgBuyPrice,
      );
    }

    _saveHoldings();
    _recomputePortfolio();
  }

  /// Coin satışı.
  ///
  /// Satış yapıldığında ortalama alış fiyatı değişmez.
  /// Miktar sıfıra ulaşırsa coin portföyden tamamen silinir.
  void sellCoin(String coinId, double amount) {
    if (amount <= 0) return;

    final current = holdings[coinId];

    if (current == null) {
      Get.snackbar(
        'Satış Hatası',
        'Bu coinden portföyünüzde bulunmuyor.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (amount > current.amount) {
      Get.snackbar(
        'Satış Hatası',
        'Sahip olduğunuz miktardan fazla satamazsınız.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updatedAmount = current.amount - amount;

    if (updatedAmount <= 0) {
      holdings.remove(coinId);
    } else {
      holdings[coinId] = PortfolioHolding(
        amount: updatedAmount,
        avgBuyPrice: current.avgBuyPrice,
      );
    }

    _saveHoldings();
    _recomputePortfolio();
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
  void deleteCoin(String coinId) {
  holdings.remove(coinId);

  _saveHoldings();
  _recomputePortfolio();
}
}
