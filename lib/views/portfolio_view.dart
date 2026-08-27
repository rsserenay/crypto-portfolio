import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/market_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/portfolio_controller.dart';
import '../theme/app_colors.dart';
import 'widgets/buy_sheet.dart';
import 'widgets/sparkline_chart.dart';
import 'coin_detail_view.dart';

class PortfolioView extends StatelessWidget {
  const PortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    final PortfolioController controller = Get.find<PortfolioController>();
    final MarketController marketController = Get.find<MarketController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(controller: controller),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: controller.onPullToRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Portföy',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(() {
                      if (controller.portfolioItems.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Henüz coin satın almadınız.\nPiyasalar sekmesinden bir coine dokunun.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 172,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: controller.portfolioItems.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = controller.portfolioItems[index];
                            final isUp = item.profitUsd >= 0;
                            return Container(
                              width: 150,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppColors.darkCardGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Get.to(() =>
                                        CoinDetailView(coinId: item.coin.id)),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 11,
                                          backgroundColor: Colors.white,
                                          backgroundImage: item.coin.image.isNotEmpty
                                              ? NetworkImage(item.coin.image)
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.coin.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: AppColors.textOnDark,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Get.to(() =>
                                          CoinDetailView(coinId: item.coin.id)),
                                      child: item.coin.sparklineData.length > 1
                                          ? SparklineChart(
                                              data: item.coin.sparklineData,
                                              lineColor: isUp
                                                  ? AppColors.accentMint
                                                  : AppColors.negative,
                                              filled: true,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  Text(
                                    '\$${item.valueUsd.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.textOnDark,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${isUp ? '▲' : '▼'} ${item.profitPercentage.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: isUp
                                          ? AppColors.accentMint
                                          : Colors.redAccent.shade100,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MiniActionButton(
                                          label: 'Al',
                                          color: AppColors.accentMint,
                                          onTap: () => Get.bottomSheet(
                                            BuySheet(coin: item.coin),
                                            backgroundColor: AppColors.surface,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(16)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _MiniActionButton(
                                          label: 'Sat',
                                          color: Colors.redAccent.shade100,
                                          onTap: () => Get.bottomSheet(
                                            BuySheet(
                                                coin: item.coin,
                                                isSelling: true),
                                            backgroundColor: AppColors.surface,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(16)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        'Güncel Fiyatlar',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  Obx(() {
                    final coins = marketController.allCoins.take(15).toList();
                    if (coins.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverList.separated(
                      itemCount: coins.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 20, endIndent: 20, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final coin = coins[index];
                        final isUp = coin.priceChangePercentage24h >= 0;
                        return ListTile(
                          onTap: () =>
                              Get.to(() => CoinDetailView(coinId: coin.id)),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.chipUnselected,
                            backgroundImage: coin.image.isNotEmpty
                                ? NetworkImage(coin.image)
                                : null,
                          ),
                          title: Text(coin.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          subtitle: Text(coin.symbol,
                              style:
                                  const TextStyle(color: AppColors.textSecondary)),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '\$${coin.currentPrice.toStringAsFixed(coin.currentPrice < 1 ? 6 : 2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                              Text(
                                '${isUp ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: isUp
                                      ? AppColors.positive
                                      : AppColors.negative,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PortfolioController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
      decoration: const BoxDecoration(
        gradient: AppColors.darkCardGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kripto Portföyüm',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  final navController = Get.find<NavigationController>();
                  navController.goToTab(1);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star, color: AppColors.accentMint, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bakiye',
                        style: TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    Obx(
                      () => Text(
                        '\$${controller.totalBalanceUsd.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Toplam Kâr/Zarar',
                        style: TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    Obx(() {
                      final isUp = controller.totalProfitUsd.value >= 0;
                      return Text(
                        '${isUp ? '+' : ''}\$${controller.totalProfitUsd.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isUp
                              ? AppColors.accentMint
                              : Colors.redAccent.shade100,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}