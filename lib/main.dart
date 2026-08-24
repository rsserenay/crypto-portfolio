import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/market_controller.dart';
import 'controllers/portfolio_controller.dart';
import 'views/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init('portfolio_box');

  // Controller'lar uygulama boyunca yaşasın diye permanent: true ile put edildi.
  // Böylece Market ve Portföy sekmeleri arasında geçiş yapılsa bile
  // Timer'lar/state kaybolmaz, onClose sadece uygulama tamamen kapanırken tetiklenir.
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
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const MainNavigation(),
    );
  }
}
