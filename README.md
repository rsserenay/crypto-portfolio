# Kripto Portföy Yöneticisi

## Kurulum
```
flutter pub get
flutter run
```

## Yapı
```
lib/
  models/coin_model.dart          -> CoinGecko JSON -> Dart model
  services/coin_api_service.dart  -> Sadece http isteği (network katmanı)
  controllers/
    market_controller.dart        -> Fetch, 500ms debounce filtreleme, sort, 30sn timer
    portfolio_controller.dart     -> GetStorage + API kombinasyonu, cüzdan hesaplama, 30sn timer
  views/
    market_view.dart              -> Sadece Obx ile controller'ı basar
    portfolio_view.dart           -> Sadece Obx ile controller'ı basar
    main_navigation.dart          -> İki sekme arası geçiş (bottom nav)
    widgets/coin_tile.dart        -> Saf UI, logic içermez
    widgets/buy_sheet.dart        -> Satın alma formu, miktarı controller'a devreder
```

## Kabul kriterleri nerede karşılanıyor?
1. **Auto-Refresh & Timer** -> `MarketController._startAutoRefresh()` ve
   `PortfolioController._startAutoRefresh()` içinde `Timer.periodic(30sn)`.
2. **Pull-to-Refresh** -> Her iki view'de de `RefreshIndicator`, controller'daki
   `onPullToRefresh()` metodunu çağırıyor (timer'dan bağımsız).
3. **View-Controller Ayrımı** -> Tüm hesaplama/filtreleme/sort/timer mantığı
   controller dosyalarında. View dosyaları sadece `Obx` + widget ağacı.
4. **Lifecycle** -> Her iki controller'ın `onClose()` metodunda
   `Timer.cancel()` çağrılıyor (bellek/network sızıntısını önler).

## Sırada ne var? (Sonraki adım için)
- `GetStorage` kutusunu ilk kullanımdan önce native tarafta initialize etmek için
  Android/iOS proje dosyalarının (android/, ios/) `flutter create .` ile
  üretilmesi gerekiyor (bu adım Flutter SDK gerektirir, bu ortamda çalıştırılamadı).
- İstersen: satılan coin'i azaltma/satma özelliği, boş arama sonucu için
  "temizle" butonu, veya toplam kâr/zarar (P&L) hesaplaması ekleyebilirim.
