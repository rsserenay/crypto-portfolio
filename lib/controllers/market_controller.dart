import 'dart:async';
import 'package:get/get.dart';
import '../models/coin_model.dart';
import '../services/coin_api_service.dart';

enum SortType { none, gainers, losers }

/// Market ekranının TÜM iş mantığı burada yaşar (Sıfır setState kuralı).
/// View sadece Obx ile bu controller'ı dinler.
class MarketController extends GetxController {
  
  final CoinApiService _apiService = CoinApiService();

  final RxList<CoinModel> allCoins = <CoinModel>[].obs;

  // Ekranda gösterilen (filtrelenmiş + sıralanmış) liste
  final RxList<CoinModel> displayedCoins = <CoinModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs; // pull-to-refresh göstergesi
  
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final Rx<SortType> activeSort = SortType.none.obs;

  Timer? _debounceTimer;
  Timer? _autoRefreshTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const Duration _autoRefreshDuration = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();
    fetchCoins();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    // Lifecycle: Timer'ları iptal etmezsek controller kapansa bile
    // arka planda çalışmaya devam edip belleği/network'ü şişirir.
    _debounceTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(_autoRefreshDuration, (_) {
      fetchCoins(silent: true);
    });
  }

  Future<void> fetchCoins({bool silent = false}) async {
  try {
    if (!silent) {
      isLoading.value = true;
    }

    hasError.value = false;
    errorMessage.value = '';

    final coins = await _apiService.fetchMarkets();

    allCoins.assignAll(coins);
    _applyFilterAndSort();
  } catch (e) {
    hasError.value = true;
    errorMessage.value = 'Piyasa verileri alınamadı.';

    if (!silent) {
      Get.snackbar(
        'Bağlantı Hatası',
        'Veriler alınamadı. Lütfen tekrar deneyin.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  } finally {
    if (!silent) {
      isLoading.value = false;
    }
  }
}
Future<void> retryFetch() async {
  await fetchCoins();
}

  /// RefreshIndicator tarafından çağrılır (manuel pull-to-refresh)
  Future<void> onPullToRefresh() async {
    isRefreshing.value = true;
    await fetchCoins(silent: true);
    isRefreshing.value = false;
  }

  /// Arama kutusundaki her tuş vuruşunda View tarafından çağrılır.
  /// API'ye İSTEK ATMAZ; sadece 500ms debounce sonrası local filtreleme yapar.
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      searchQuery.value = query.trim();
      _applyFilterAndSort();
    });
  }

  void sortByGainers() {
    activeSort.value = SortType.gainers;
    _applyFilterAndSort();
  }

  void sortByLosers() {
    activeSort.value = SortType.losers;
    _applyFilterAndSort();
  }

  void clearSort() {
    activeSort.value = SortType.none;
    _applyFilterAndSort();
  }

  /// Elde bulunan 100 coinlik listeyi Dart tarafında filtreler ve sıralar.
  void _applyFilterAndSort() {
    List<CoinModel> result = allCoins.toList();

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where((coin) =>
              coin.name.toLowerCase().contains(q) ||
              coin.symbol.toLowerCase().contains(q))
          .toList();
    } 

    switch (activeSort.value) {
      case SortType.gainers:
        result.sort((a, b) => b.priceChangePercentage24h
            .compareTo(a.priceChangePercentage24h));
        break;
      case SortType.losers:
        result.sort((a, b) => a.priceChangePercentage24h
            .compareTo(b.priceChangePercentage24h));
        break;
      case SortType.none:
        break;
    }

    displayedCoins.assignAll(result);
  }
  void clearSearch() {
  _debounceTimer?.cancel();
  searchQuery.value = '';
  _applyFilterAndSort();
}

}
