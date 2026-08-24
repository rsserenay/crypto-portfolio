import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/market_controller.dart';
import '../controllers/portfolio_controller.dart';
import 'widgets/coin_tile.dart';
import 'widgets/buy_sheet.dart';

class MarketView extends StatefulWidget {
  const MarketView({super.key});

  @override
  State<MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final MarketController controller = Get.find<MarketController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Piyasalar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Obx(
  () => TextField(
    controller: _searchController,
    onChanged: controller.onSearchChanged,
    decoration: InputDecoration(
      hintText: 'Coin ara (örn: bitcoin, btc)',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: controller.searchQuery.value.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                controller.clearSearch();
              },
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      isDense: true,
    ),
  ),
),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(
              () => Row(
                children: [
                  _SortChip(
                    label: 'En Çok Yükselenler',
                    selected: controller.activeSort.value == SortType.gainers,
                    onTap: controller.sortByGainers,
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'En Çok Düşenler',
                    selected: controller.activeSort.value == SortType.losers,
                    onTap: controller.sortByLosers,
                  ),
                  const SizedBox(width: 8),
                  if (controller.activeSort.value != SortType.none)
                    ActionChip(
                      label: const Text('Sıfırla'),
                      onPressed: controller.clearSort,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

if (controller.hasError.value) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_off,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          controller.errorMessage.value,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: controller.retryFetch,
          child: const Text('Tekrar Dene'),
        ),
      ],
    ),
  );
}

if (controller.displayedCoins.isEmpty) {
  final query = controller.searchQuery.value;

  return Center(
    child: Text(
      query.isEmpty
          ? 'Sonuç bulunamadı'
          : '"$query" için sonuç bulunamadı',
    ),
  );
}
              
              return RefreshIndicator(
                onRefresh: controller.onPullToRefresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.displayedCoins.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final coin = controller.displayedCoins[index];
                    return CoinTile(
                      coin: coin,
                      onTap: () {
                        // PortfolioController'ın izinli olduğundan emin oluyoruz
                        Get.find<PortfolioController>();
                        Get.bottomSheet(
                          BuySheet(coin: coin),
                          backgroundColor: Colors.white,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                        );
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
    );
  }
}
