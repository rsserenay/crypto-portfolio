import 'dart:math';

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

                  // --- PERFORMANS: en çok kazandıran / en çok kaybettiren coin ---
                  Obx(() {
                    if (controller.portfolioItems.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Text(
                              'Performans',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          _PerformanceHighlights(
                            items: controller.portfolioItems,
                          ),
                        ],
                      ),
                    );
                  }),

                  // --- PORTFÖY DAĞILIMI: hangi coin toplamın yüzde kaçı ---
                  Obx(() {
                    if (controller.portfolioItems.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Text(
                              'Portföy Dağılımı',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          _AllocationSection(
                            items: controller.portfolioItems,
                            totalUsd: controller.totalBalanceUsd.value,
                          ),
                        ],
                      ),
                    );
                  }),

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

/// Portföydeki her coinin toplam bakiyeye oranını yığın çubuk (stacked bar)
/// ve altında yüzdelik bir liste olarak gösterir. Harici bir grafik paketi
/// kullanmadan, sade Flutter widget'larıyla yapılmıştır.
class _AllocationSection extends StatelessWidget {
  final List<PortfolioItem> items;
  final double totalUsd;

  const _AllocationSection({
    required this.items,
    required this.totalUsd,
  });

  // Coinleri ayırt etmek için sabit bir renk paleti.
  // Coin sayısı palet uzunluğunu aşarsa baştan tekrar kullanılır.
  static const List<Color> _palette = [
    Color(0xFF7C4DFF),
    Color(0xFF00BFA5),
    Color(0xFFFF6D91),
    Color(0xFFFFAB40),
    Color(0xFF40C4FF),
    Color(0xFFAED581),
    Color(0xFFFF8A65),
    Color(0xFFBA68C8),
  ];

  @override
  Widget build(BuildContext context) {
    if (totalUsd <= 0 || items.isEmpty) {
      return const SizedBox.shrink();
    }

    // En büyük paydan en küçüğe doğru sırala.
    final sorted = [...items]
      ..sort((a, b) => b.valueUsd.compareTo(a.valueUsd));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DonutChart(
              items: sorted,
              totalUsd: totalUsd,
              palette: _palette,
            ),
            const SizedBox(width: 20),
            // Coin bazlı yüzdelik liste (sağ taraf, kalan alanı kaplar).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(sorted.length, (i) {
                  final item = sorted[i];
                  final pct = (item.valueUsd / totalUsd) * 100;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == sorted.length - 1 ? 0 : 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _palette[i % _palette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.coin.symbol,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ek bir grafik paketi kullanmadan, CustomPainter ile çizilen basit bir
/// halka (donut) grafiği. Ortasında toplam bakiyeyi gösterir.
class _DonutChart extends StatelessWidget {
  final List<PortfolioItem> items;
  final double totalUsd;
  final List<Color> palette;

  const _DonutChart({
    required this.items,
    required this.totalUsd,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final ratios = items
        .map((e) => totalUsd > 0 ? e.valueUsd / totalUsd : 0.0)
        .toList();

    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(128, 128),
            painter: _DonutChartPainter(
              ratios: ratios,
              colors: palette,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Toplam',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${totalUsd.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> ratios;
  final List<Color> colors;
  static const double _strokeWidth = 20;

  _DonutChartPainter({
    required this.ratios,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    // Saat 12 yönünden (yukarıdan) başlayıp saat yönünde ilerliyoruz.
    double startAngle = -pi / 2;

    for (int i = 0; i < ratios.length; i++) {
      // Çok küçük dilimlerin görünür olması için minik bir alt sınır koyuyoruz.
      final sweepAngle = (ratios[i] * 2 * pi).clamp(0.0, 2 * pi);

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.ratios != ratios || oldDelegate.colors != colors;
  }
}

/// Portföydeki coinler arasında en yüksek kâr yüzdesine ve en yüksek
/// zarar yüzdesine sahip olanları yan yana iki kart halinde gösterir.
/// Tek bir coin varsa (karşılaştırma anlamsız olacağı için) yalnızca
/// "En Çok Kazandıran" kartı gösterilir.
class _PerformanceHighlights extends StatelessWidget {
  final List<PortfolioItem> items;

  const _PerformanceHighlights({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final sorted = [...items]
      ..sort((a, b) => b.profitPercentage.compareTo(a.profitPercentage));

    final best = sorted.first;
    final worst = sorted.last;
    final bool onlyOneHolding = items.length == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _PerformanceCard(
              title: 'En Çok Kazandıran',
              item: best,
              icon: Icons.trending_up,
              color: AppColors.positive,
            ),
          ),
          if (!onlyOneHolding) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                title: 'En Çok Kaybettiren',
                item: worst,
                icon: Icons.trending_down,
                color: AppColors.negative,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final PortfolioItem item;
  final IconData icon;
  final Color color;

  const _PerformanceCard({
    required this.title,
    required this.item,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUp = item.profitUsd >= 0;

    return GestureDetector(
      onTap: () => Get.to(() => CoinDetailView(coinId: item.coin.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.chipUnselected,
                  backgroundImage: item.coin.image.isNotEmpty
                      ? NetworkImage(item.coin.image)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.coin.symbol,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${isUp ? '+' : ''}${item.profitPercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${isUp ? '+' : ''}\$${item.profitUsd.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                  // Önce Market'teki filtreyi "Favoriler"e çeviriyoruz,
                  // sonra Market sekmesine geçiyoruz. Böylece kullanıcı
                  // doğrudan favori coinlerinin listesini görür.
                  final marketController = Get.find<MarketController>();
                  marketController.sortByFavorites();

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