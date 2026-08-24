import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';

/// Sadece CoinGecko API'sine HTTP isteği atmaktan sorumludur.
/// İçinde hiçbir state/UI mantığı yoktur; sadece network katmanıdır.
class CoinApiService {
  static const String _baseUrl =
      'https://api.coingecko.com/api/v3/coins/markets'
      '?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false';

  Future<List<CoinModel>> fetchMarkets() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CoinModel.fromJson(e)).toList();
    } else {
      throw Exception('CoinGecko API hatası: ${response.statusCode}');
    }
  }
}
