import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';

/// Sadece CoinGecko API'sine HTTP isteği atmaktan sorumludur.
/// İçinde hiçbir state/UI mantığı yoktur; sadece network katmanıdır.
class CoinApiService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  /// En büyük 100 coini, 24h değişim ve 7 günlük sparkline verisiyle çeker.
  Future<List<CoinModel>> fetchMarkets() async {
    final uri = Uri.parse(
      '$_baseUrl/coins/markets'
      '?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=true',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CoinModel.fromJson(e)).toList();
    } else {
      throw Exception('CoinGecko API hatası: ${response.statusCode}');
    }
  }

  /// Piyasa geneli özet verisi (toplam piyasa değeri, hacim, BTC dominansı).
  Future<GlobalMarketData> fetchGlobalData() async {
    final uri = Uri.parse('$_baseUrl/global');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return GlobalMarketData.fromJson(data);
    } else {
      throw Exception('CoinGecko Global API hatası: ${response.statusCode}');
    }
  }

  /// Belirli bir coin için OHLC (mum) verisini çeker.
  /// [days]: CoinGecko ücretsiz planda desteklenen değerler: 1, 7, 14, 30, 90, 180, 365, max
  Future<List<CandleModel>> fetchOhlc(String coinId, int days) async {
    final uri = Uri.parse(
      '$_baseUrl/coins/$coinId/ohlc?vs_currency=usd&days=$days',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => CandleModel.fromList(e as List<dynamic>))
          .toList();
    } else {
      throw Exception('CoinGecko OHLC API hatası: ${response.statusCode}');
    }
  }
}