import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/market_controller.dart';
import '../theme/app_colors.dart';
import 'widgets/coin_tile.dart';
import 'coin_detail_view.dart';

class MarketView extends StatelessWidget {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context) {
    final MarketController controller = Get.find<MarketController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnDark,
        title: Obx(() {
          final coins = controller.allCoins;
          double avgChange = 0;
          if (coins.isNotEmpty) {
            avgChange = coins
                    .map((c) => c.priceChangePercentage24h)
                    .reduce((a, b) => a + b) /
                coins.length;
          }
          final isUp = avgChange >= 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Piyasa Trendleri'),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${isUp ? '▲' : '▼'} ${avgChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUp ? AppColors.accentMint : AppColors.negative,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Obx(
              () => TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Coin ara (örn: bitcoin, btc)',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SortChip(
                      label: 'Tümü',
                      selected: controller.activeSort.value == SortType.none,
                      onTap: controller.clearSort,
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'En Çok Yükselenler',
                      selected:
                          controller.activeSort.value == SortType.gainers,
                      onTap: controller.sortByGainers,
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'En Çok Düşenler',
                      selected: controller.activeSort.value == SortType.losers,
                      onTap: controller.sortByLosers,
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: '⭐ Favoriler',
                      selected:
                          controller.activeSort.value == SortType.favorites,
                      onTap: controller.sortByFavorites,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.hasError.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnDark,
                        ),
                        onPressed: controller.retryFetch,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.displayedCoins.isEmpty) {
                final query = controller.searchQuery.value;

                String message;
                if (query.isNotEmpty) {
                  message = '"$query" için sonuç bulunamadı';
                } else if (controller.activeSort.value ==
                    SortType.favorites) {
                  message = 'Henüz favori coin eklemediniz.\n'
                      'Bir coinin yanındaki yıldıza dokunarak favorilere ekleyebilirsiniz.';
                } else {
                  message = 'Gösterilecek coin bulunamadı';
                }

                return Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.onPullToRefresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: controller.displayedCoins.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, index) {
                    final coin = controller.displayedCoins[index];
                    return CoinTile(
                      coin: coin,
                      onTap: () {
                        Get.to(() => CoinDetailView(coinId: coin.id));
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.chipUnselected,
      labelStyle: TextStyle(
        color: selected ? AppColors.textOnDark : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}