import 'dart:async';
import 'package:get/get.dart';
import '../models/coin_model.dart';
import '../services/coin_api_service.dart';
import 'market_controller.dart';

enum ChartTimeframe {
  oneDay(label: '1G', days: 1),
  oneWeek(label: '7G', days: 7),
  oneMonth(label: '1A', days: 30),
  threeMonths(label: '3A', days: 90),
  oneYear(label: '1Y', days: 365);

  final String label;
  final int days;

  const ChartTimeframe({required this.label, required this.days});
}

/// Coin detay ekranının TÜM iş mantığı burada yaşar.
/// Güncel fiyat MarketController'dan (tek kaynak) beslenir;
/// candlestick verisi ise coin'e özel ayrı bir API çağrısıyla gelir.
class CoinDetailController extends GetxController {
  final String coinId;
  CoinDetailController(this.coinId);

  final CoinApiService _apiService = CoinApiService();
  final MarketController _marketController = Get.find<MarketController>();

  final Rx<CoinModel?> coin = Rx<CoinModel?>(null);
  final RxList<CandleModel> candles = <CandleModel>[].obs;
  final Rx<ChartTimeframe> selectedTimeframe = ChartTimeframe.oneWeek.obs;

  final RxBool isChartLoading = false.obs;
  final RxBool isFavorite = false.obs;

  late final Worker _coinWorker;
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshDuration = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();

    _updateCoinFromMarket();
    _coinWorker = ever<List<CoinModel>>(
      _marketController.allCoins,
      (_) => _updateCoinFromMarket(),
    );

    fetchCandles();

    _autoRefreshTimer = Timer.periodic(_autoRefreshDuration, (_) {
      fetchCandles(silent: true);
    });
  }

  @override
  void onClose() {
    _coinWorker.dispose();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  void _updateCoinFromMarket() {
    try {
      coin.value = _marketController.allCoins.firstWhere(
        (c) => c.id == coinId,
      );
    } catch (_) {
      // Coin bulunamadıysa mevcut değeri korur.
    }
  }

  void selectTimeframe(ChartTimeframe timeframe) {
    if (selectedTimeframe.value == timeframe) return;
    selectedTimeframe.value = timeframe;
    fetchCandles();
  }

  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
  }

  Future<void> fetchCandles({bool silent = false}) async {
    try {
      if (!silent) isChartLoading.value = true;
      final result = await _apiService.fetchOhlc(
        coinId,
        selectedTimeframe.value.days,
      );
      candles.assignAll(result);
    } catch (_) {
      // Sessizce geç: grafik alanı "veri yok" mesajını kendi gösterir.
    } finally {
      if (!silent) isChartLoading.value = false;
    }
  }
}
