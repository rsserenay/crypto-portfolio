import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
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

    const pages = [PortfolioView(), MarketView()];

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex.value == 0,
                  onTap: () => currentIndex.value = 0,
                ),
                _NavItem(
                  icon: Icons.show_chart_rounded,
                  label: 'Market',
                  selected: currentIndex.value == 1,
                  onTap: () => currentIndex.value = 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentMint.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.accentMint : AppColors.textOnDarkSecondary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.accentMint
                      : AppColors.textOnDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
