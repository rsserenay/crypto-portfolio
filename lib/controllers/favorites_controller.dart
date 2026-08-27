import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Favori coinlerin tüm mantığı burada yaşar: ekleme/çıkarma ve
/// GetStorage'a kalıcı kaydetme. View'ler sadece favoriteIds'i okur.
class FavoritesController extends GetxController {
  final GetStorage _box = GetStorage('favorites_box');
  static const String _storageKey = 'favorite_ids';

  final RxSet<String> favoriteIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final List<dynamic>? raw = _box.read(_storageKey);
    if (raw != null) {
      favoriteIds.assignAll(raw.map((e) => e.toString()));
    }
  }

  bool isFavorite(String coinId) => favoriteIds.contains(coinId);

  void toggleFavorite(String coinId) {
    if (favoriteIds.contains(coinId)) {
      favoriteIds.remove(coinId);
    } else {
      favoriteIds.add(coinId);
    }
    _box.write(_storageKey, favoriteIds.toList());
  }
}