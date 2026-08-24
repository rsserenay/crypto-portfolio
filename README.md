# Kripto Portföy Yöneticisi

CoinGecko API üzerinden piyasa verilerini gösteren, kullanıcıların coin alıp satabildiği ve portföy değerlerini anlık piyasa fiyatları üzerinden takip edebildiği Flutter uygulaması.

## Özellikler

- CoinGecko API'den en yüksek piyasa değerine sahip 100 coin'i görüntüleme
- Coin adına veya sembolüne göre arama
- 500 ms debounce ile local arama/filtreleme
- En çok yükselenleri ve en çok düşenleri sıralama
- 30 saniyede bir otomatik piyasa verisi yenileme
- Pull-to-refresh ile manuel yenileme
- Coin satın alma
- Coin satma
- Aynı coin'den birden fazla alımda ortalama alış fiyatı hesaplama
- Satış sonrasında ortalama alış fiyatını koruma
- GetStorage ile portföy verilerini cihazda saklama
- Toplam cüzdan değerini hesaplama
- Toplam yatırılan tutarı ve toplam kâr/zararı hesaplama
- Coin bazında kâr/zarar yüzdesini gösterme
- Portföyden coin silme

## Kurulum

```bash
flutter pub get
flutter run
```

## Mimari

```text
lib/
├── models/
│   ├── coin_model.dart          -> CoinGecko JSON verisini Dart modeline dönüştürür
│   └── portfolio_holding.dart   -> Portföyde tutulan miktar ve ortalama alış fiyatını temsil eder
│
├── services/
│   └── coin_api_service.dart    -> CoinGecko API'ye HTTP isteği atar
│
├── controllers/
│   ├── market_controller.dart   -> API verisi, arama, filtreleme, sıralama ve 30 sn otomatik yenileme
│   └── portfolio_controller.dart
│                                  -> GetStorage, alım/satım ve portföy hesaplamalarını yönetir
│
└── views/
    ├── market_view.dart         -> Piyasa ekranı ve controller verilerinin gösterimi
    ├── portfolio_view.dart      -> Portföy ekranı ve controller verilerinin gösterimi
    ├── main_navigation.dart     -> Piyasalar ve Portföyüm sekmeleri arasında geçiş
    │
    └── widgets/
        ├── coin_tile.dart       -> Coin bilgilerini gösteren saf UI widget'ı
        └── buy_sheet.dart       -> Coin alım/satım formu
```

## Teknik Detaylar

### 1. Auto-Refresh & Timer

`MarketController`, `Timer.periodic` kullanarak her 30 saniyede bir CoinGecko API'den piyasa verilerini yeniler.

`PortfolioController` kendi timer'ını çalıştırmaz. Bunun yerine `MarketController.allCoins` listesini GetX `ever()` worker'ı ile dinler. Market verileri yenilendiğinde portföy fiyatları ve kâr/zarar hesaplamaları otomatik olarak güncellenir.

### 2. Pull-to-Refresh

Hem `MarketView` hem de `PortfolioView` içerisinde `RefreshIndicator` bulunur.

- `MarketView` → `MarketController.onPullToRefresh()`
- `PortfolioView` → `PortfolioController.onPullToRefresh()`

Portfolio ekranındaki manuel yenileme de aynı `MarketController` üzerinden güncel piyasa verilerini çeker.

### 3. View - Controller Ayrımı

İş mantığı controller katmanında tutulur.

- `MarketController` → API çağrısı sonrası liste yönetimi, arama, filtreleme ve sıralama
- `PortfolioController` → alım/satım, ortalama alış fiyatı, portföy değeri ve kâr/zarar hesaplamaları
- `CoinApiService` → yalnızca network/API işlemleri
- View ve widget'lar → UI gösterimi ve kullanıcı etkileşimlerini controller metodlarına iletme

`CoinTile` içerisinde market cap gösterimi için kullanılan formatlama da modeldeki `formattedMarketCap` getter'ı üzerinden sağlanır.

### 4. Lifecycle

Controller'lar uygulama başlangıcında `permanent: true` ile oluşturulur. Böylece sekmeler arasında geçiş yapıldığında controller state'i ve MarketController'ın otomatik yenileme timer'ı kaybolmaz.

`MarketController.onClose()` içerisinde:

- debounce timer
- otomatik yenileme timer'ı
- search controller

temizlenir.

`PortfolioController.onClose()` içerisinde ise `ever()` worker'ı `dispose()` edilir.

## Veri Saklama

Portföy verileri `GetStorage` kullanılarak cihazda saklanır.

Uygulama başlangıcında:

```dart
await GetStorage.init('portfolio_box');
```

ile storage başlatılır.

Her coin için:

- sahip olunan miktar
- ortalama alış fiyatı

saklanır.

Güncel coin fiyatları ise CoinGecko API'den alınır. Bu iki veri birleştirilerek portföy değeri ve kâr/zarar hesaplanır.

## Portföy Hesaplamaları

Yeni bir coin alındığında ortalama alış fiyatı ağırlıklı ortalama ile güncellenir:

```text
Yeni Ortalama Alış Fiyatı =
(Eski Miktar × Eski Ortalama Alış Fiyatı
 + Yeni Miktar × Güncel Fiyat)
 / Toplam Miktar
```

Satış yapıldığında ortalama alış fiyatı değiştirilmez. Satılan miktar mevcut miktardan düşülür. Miktar sıfıra ulaştığında coin portföyden kaldırılır.

Kâr/zarar:

```text
Kâr/Zarar = Güncel Portföy Değeri - Yatırılan Tutar
```

Kâr/zarar yüzdesi:

```text
Kâr/Zarar % = (Kâr/Zarar / Yatırılan Tutar) × 100
```

## Kullanılan Teknolojiler

- Flutter
- Dart
- GetX
- GetStorage
- HTTP
- CoinGecko API

## Lisans

Bu proje [MIT License](LICENSE) altında lisanslanmıştır.
