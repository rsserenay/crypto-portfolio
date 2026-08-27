import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/market_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/portfolio_controller.dart';
import 'theme/app_colors.dart';
import 'views/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init('portfolio_box');
  await GetStorage.init('favorites_box');

  // Sıra önemli: MarketController FavoritesController'ı,
  // PortfolioController da MarketController'ı Get.find ile arıyor.
  Get.put(NavigationController(), permanent: true);
  Get.put(FavoritesController(), permanent: true);
  Get.put(MarketController(), permanent: true);
  Get.put(PortfolioController(), permanent: true);

  runApp(const KriptoPortfoyApp());
}

class KriptoPortfoyApp extends StatelessWidget {
  const KriptoPortfoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kripto Portföy Yöneticisi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accentMint,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnDark,
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}