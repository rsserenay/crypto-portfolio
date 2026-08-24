import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/coin_model.dart';
import 'market_controller.dart';

/// Cüzdanda görünecek tek satır: coin bilgisi + kullanıcının sahip olduğu miktar + o anki USD değeri
class PortfolioItem {
  final CoinModel coin;
  final double amount;
  double get valueUsd => coin.currentPrice * amount;

  PortfolioItem({required this.coin, required this.amount});
}

/// Portföy ekranının TÜM iş mantığı burada yaşar.
/// GetStorage'daki (miktar) veri ile API'den gelen (anlık fiyat) veri
/// burada ID bazlı eşleştirilir. View sadece sonucu Obx ile basar.
class PortfolioController extends GetxController {
  final GetStorage _box = GetStorage('portfolio_box');

  static const String _storageKey = 'portfolio_holdings'; // {"bitcoin": 0.5, ...}

  // coinId -> sahip olunan miktar (GetStorage'dan okunan ham veri)
  final RxMap<String, double> holdings = <String, double>{}.obs;

  // API'den gelen tüm coin fiyat verisi (id -> CoinModel), hızlı eşleştirme için map
  final RxMap<String, CoinModel> _priceMap = <String, CoinModel>{}.obs;

  // View'in gösterdiği nihai kombinasyon: sadece elde bulunan coinler + değerleri
  final RxList<PortfolioItem> portfolioItems = <PortfolioItem>[].obs;
  final MarketController _marketController = Get.find<MarketController>();
  final RxDouble totalBalanceUsd = 0.0.obs;
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
        holdings[key] = (value as num).toDouble();
      });
    }
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

  /// Satın alma formu tarafından çağrılır. Miktarı GetStorage'a kaydeder
  /// (mevcut miktar varsa üzerine ekler) ve portföyü yeniden hesaplar.
  void buyCoin(String coinId, double amount) {
    if (amount <= 0) return;

    final current = holdings[coinId] ?? 0.0;
    final updated = current + amount;
    holdings[coinId] = updated;

    final Map<String, dynamic> toSave = holdings.map(
      (key, value) => MapEntry(key, value),
    );
    _box.write(_storageKey, toSave);

    _recomputePortfolio();
  }
  void sellCoin(String coinId, double amount) {
  if (amount <= 0) return;

  final current = holdings[coinId] ?? 0.0;

  if (amount > current) {
    Get.snackbar(
      'Satış Hatası',
      'Sahip olduğunuz miktardan fazla satamazsınız.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  final updated = current - amount;

  if (updated <= 0) {
    holdings.remove(coinId);
  } else {
    holdings[coinId] = updated;
  }

  final Map<String, dynamic> toSave = holdings.map(
    (key, value) => MapEntry(key, value),
  );

  _box.write(_storageKey, toSave);

  _recomputePortfolio();
}

  /// GetStorage'daki "miktar" ile API'den gelen "anlık fiyat" verisini
  /// coin ID'sine göre eşleştirip (Miktar * Fiyat) toplam bakiyeyi hesaplar.
  void _recomputePortfolio() {
    final List<PortfolioItem> items = [];
    double total = 0.0;

    holdings.forEach((coinId, amount) {
      final coin = _priceMap[coinId];
      if (coin != null && amount > 0) {
        final item = PortfolioItem(coin: coin, amount: amount);
        items.add(item);
        total += item.valueUsd;
      }
    });

    items.sort((a, b) => b.valueUsd.compareTo(a.valueUsd));

    portfolioItems.assignAll(items);
    totalBalanceUsd.value = total;
  }
}
