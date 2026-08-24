---
name: flutter-hata-teshisi
description: "Flutter veya Dart projelerinde birçok dosyada aynı anda görünen analizör, import, bağımlılık, SDK ve derleme hatalarını kök nedene göre teşhis et. 'Neden bütün dosyalarda hata var', 'her dosyada kırmızı çizgi', 'Flutter hata veriyor' gibi durumlarda kullan."
argument-hint: "Hata belirtilerini, ilk görülen tanıyı veya çalıştırılan komutu yazın"
user-invocable: true
---

# Flutter Hata Teşhisi

## Amaç

Birden fazla dosyada görünen hataların tek tek dosya hataları mı, yoksa ortak bir proje yapılandırması veya araç zinciri sorunu mu olduğunu kanıtlarla ayır. Gereksiz dosya değişikliği yapmadan en küçük düzeltmeyi uygula.

## Ne Zaman Kullanılır

- Projedeki dosyaların çoğunda aynı anda hata görünüyorsa
- Import'lar, paketler veya Flutter sınıfları çözümlenmiyorsa
- VS Code analizörü ile `flutter analyze` sonuçları farklıysa
- `pubspec.yaml`, Flutter SDK, Dart SDK veya generated dosyalarla ilgili hata varsa
- Kullanıcı hatanın nedenini ve nasıl doğrulanacağını soruyorsa

## İş Akışı

1. **Kapsamı sabitle**
   - İlk tanıyı, etkilenen dosyaları ve hata türlerinin ortak metnini topla.
   - `pubspec.yaml`, ilgili dosyanın import bölümü ve proje kökündeki Flutter yapılandırmasını oku.
   - Önce hata listesini al; yalnızca editördeki kırmızı çizgilere göre varsayım yapma.

2. **Ortak kök nedeni test et**
   - Proje kökünde `flutter pub get` çalıştır.
   - Ardından `flutter analyze` çalıştır ve ilk kök hatayı ayır.
   - SDK sürümünü `flutter --version` ile, kullanılan Dart sürümünü de aynı çıktıyla kontrol et.
   - Bağımlılık çözümlemesi başarısızsa uygulama dosyalarını değiştirme; önce paket veya SDK sorununu düzelt.

3. **Hata desenini sınıflandır**
   - `Target of URI doesn't exist` veya çözümlenemeyen paket import'ları: paket alınmamış, yanlış dependency veya bozuk package config.
   - `Undefined class`, `Undefined name` veya Flutter API hataları: SDK sürümü/API uyumsuzluğu ya da önceki import hatasının zincirleme sonucu.
   - Tek dosyada syntax/type hatası: yerel kod sorunu; yalnızca ilgili akışı incele.
   - `pubspec.yaml` biçim veya sürüm hatası: YAML ve SDK constraint'lerini düzeltmeden diğer tanıları yorumlama.
   - VS Code'da hata var, `flutter analyze` temiz: analizör önbelleği veya seçili Flutter SDK uyuşmazlığı; Dart/Flutter analizörünü yeniden başlatıp tekrar doğrula.

4. **İlk kök hatayı düzelt**
   - En fazla bir küçük ve neden-sonuç ilişkisi açık değişiklik yap.
   - Zincirleme tanıları tek tek susturmak için import, tip veya dosya değişiklikleri ekleme.
   - Paket API'si belirsizse yerel paket metadata'sını veya resmi paket dokümantasyonunu kontrol et.

5. **Aynı kapsamda doğrula**
   - Önce aynı dar komutu yeniden çalıştır: `flutter analyze` veya başarısız olan test.
   - Sonra gerekirse `flutter test` ve `flutter build` ile daha geniş doğrulama yap.
   - Tanılayıcı hâlâ yalnızca VS Code'da görünüyorsa analizörün kullandığı SDK yolunu Flutter projesinin SDK'sıyla karşılaştır.

## Karar Noktaları

- `flutter pub get` başarısızsa: bağımlılık/SDK çözümlemesini düzelt; kaynak dosyalarına dokunma.
- `flutter pub get` başarılı, `flutter analyze` ilk ortak import hatasında duruyorsa: package config veya dependency tanımını incele.
- `flutter analyze` yalnızca birkaç dosyada hata veriyorsa: ortak proje sorunundan yerel kod incelemesine geç.
- Hiçbir komut hata vermiyor ama editör kırmızı gösteriyorsa: analizör önbelleğini yenile, doğru workspace kökünü ve SDK seçimini kontrol et.
- Hata yalnızca çalışma zamanında oluşuyorsa: statik analiz akışından çıkıp stack trace ve ilgili controller/widget yaşam döngüsünü incele.

## Tamamlanma Kriterleri

- Kök neden en az bir komut çıktısı veya kesin bir tanıyla desteklenmiş olmalı.
- Aynı hatayı üreten dosyalarda gereksiz toplu değişiklik yapılmamalı.
- `flutter analyze` temiz olmalı veya kalan hatalar açıkça bağımsız ve listelenmiş olmalı.
- Kullanıcıya çalıştırılan doğrulama komutu ve sonucu kısa biçimde bildirilmelidir.
- Araç/SDK sorunuysa hangi SDK'nın seçilmesi veya hangi komutun yeniden çalıştırılması gerektiği belirtilmelidir.
