import 'package:flutter/material.dart';

/// Uygulamanın tüm renkleri tek yerden yönetilir.
/// Verilen palette'den seçilen 4 ana renk kullanılıyor:
/// - primary / primaryDark: marka rengi (butonlar, koyu kartlar, nav)
/// - accentMint: pozitif/yükseliş vurgusu
/// - background: genel zemin
/// Kırmızı (negative) palette dışında; finansal UI'da düşüşü evrensel
/// olarak okunabilir kılmak için gerekli fonksiyonel bir renk.
class AppColors {
  AppColors._();

  // --- Palette'den seçilen 4 renk ---
  static const Color primary = Color(0xFF2C5EAD);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accentMint = Color(0xFF98E8DE);
  static const Color background = Color(0xFFF4F4F4);

  // --- Yüzey / Nötr ---
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF14213D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkSecondary = Color(0xFFB8C4E0);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color chipUnselected = Color(0xFFEDEFF3);

  // --- Durum Renkleri (accentMint'ten türetilen pozitif + fonksiyonel negatif) ---
  static const Color positive = Color(0xFF2FB897); // accentMint'in koyu/okunabilir tonu
  static const Color positiveSoft = Color.fromARGB(255, 113, 230, 216);
  static const Color negative = Color(0xFFE5484D);
  static const Color negativeSoft = Color(0xFFFBD5D5);

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );
}
