import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'market_view.dart';
import 'portfolio_view.dart';

/// Sadece iki sekme arasında geçiş yapan basit bir kabuk (shell) widget'ı.
/// Aktif index bilgisi burada bir Rx ile tutulur; bu bir "index" UI durumudur,
/// hesaplama/filtreleme/sort/timer gibi bir iş mantığı içermez.
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;

    final pages = const [MarketView(), PortfolioView()];

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex.value,
          onDestinationSelected: (i) => currentIndex.value = i,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              label: 'Piyasalar',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Portföyüm',
            ),
          ],
        ),
      ),
    );
  }
}
