import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/coin_detail_controller.dart';
import '../controllers/portfolio_controller.dart';
import '../models/portfolio_holding.dart';
import '../theme/app_colors.dart';
import 'widgets/candlestick_chart.dart';
import 'widgets/buy_sheet.dart';

class CoinDetailView extends StatelessWidget {
  final String coinId;

  const CoinDetailView({super.key, required this.coinId});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(CoinDetailController(coinId), tag: coinId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
            Get.delete<CoinDetailController>(tag: coinId);
          },
        ),
        title: Obx(() {
          final coin = controller.coin.value;

          if (coin == null) {
            return const SizedBox.shrink();
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                backgroundImage:
                    coin.image.isNotEmpty ? NetworkImage(coin.image) : null,
              ),
              const SizedBox(width: 10),
              Text(coin.name),
              const SizedBox(width: 6),
              Text(
                '(${coin.symbol})',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ],
          );
        }),
        actions: [
          Obx(() {
            final coin = controller.coin.value;

            final isFav = coin != null &&
                controller.favoritesController.isFavorite(coin.id);

            return IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav
                    ? AppColors.accentMint
                    : AppColors.textOnDark,
              ),
              onPressed: controller.toggleFavorite,
            );
          }),
        ],
      ),
      body: Obx(() {
        final coin = controller.coin.value;

        if (coin == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final bool isUp = coin.priceChangePercentage24h >= 0;

        final Color changeColor =
            isUp ? AppColors.positive : AppColors.negative;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${coin.currentPrice.toStringAsFixed(
                  coin.currentPrice < 1 ? 6 : 2,
                )}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isUp
                      ? AppColors.positiveSoft.withValues(alpha: 0.4)
                      : AppColors.negativeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isUp ? '▲' : '▼'} '
                  '${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Zaman aralığı sekmeleri
              Obx(
                () => Row(
                  children: ChartTimeframe.values.map((tf) {
                    final selected =
                        controller.selectedTimeframe.value == tf;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tf.label),
                        selected: selected,
                        onSelected: (_) =>
                            controller.selectTimeframe(tf),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.chipUnselected,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Candlestick grafik
              SizedBox(
                height: 220,
                child: Obx(() {
                  if (controller.isChartLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return CandlestickChart(
                    candles: controller.candles,
                  );
                }),
              ),

              const SizedBox(height: 24),

              // 24H istatistikleri
              Row(
                children: [
                  _StatBox(
                    label: '24H Yüksek',
                    value: '\$${coin.high24h.toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: '24H Düşük',
                    value: '\$${coin.low24h.toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: '24H Hacim',
                    value: coin.formattedVolume,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    // SATIN AL
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentMint,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Get.find<PortfolioController>();

                          Get.bottomSheet(
                            BuySheet(coin: coin),
                            backgroundColor: AppColors.surface,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Satın Al',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // SAT
                    Obx(() {
                      final portfolioController =
                          Get.find<PortfolioController>();

                      final owns = portfolioController.portfolioItems
                          .any((item) => item.coin.id == coin.id);

                      if (!owns) {
                        return const SizedBox.shrink();
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.negative,
                              side: const BorderSide(
                                color: AppColors.negative,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Get.bottomSheet(
                                BuySheet(
                                  coin: coin,
                                  isSelling: true,
                                ),
                                backgroundColor: AppColors.surface,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Sat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- PORTFÖYÜMDEKİ DURUM + İŞLEM GEÇMİŞİ ---
              // holdings RxMap olduğu için Obx bu bloğu otomatik günceller:
              // alım/satım yapıldığı anda burası da tazelenir.
              Obx(() {
                final portfolioController = Get.find<PortfolioController>();
                final holding = portfolioController.holdings[coin.id];
                final transactions =
                    portfolioController.transactionsFor(coin.id);

                final bool hasPosition =
                    holding != null && holding.amount > 0;

                if (holding == null && transactions.isEmpty) {
                  return const SizedBox.shrink();
                }

                double investedUsd = 0;
                double ownedValueUsd = 0;
                double profitUsd = 0;
                double profitPct = 0;

                if (hasPosition) {
                  ownedValueUsd = holding.amount * coin.currentPrice;
                  investedUsd = holding.amount * holding.avgBuyPrice;
                  profitUsd = ownedValueUsd - investedUsd;
                  profitPct =
                      investedUsd > 0 ? (profitUsd / investedUsd) * 100 : 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPosition) ...[
                      const Text(
                        'Portföyümdeki Durumum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              label: 'Sahip Olunan',
                              value:
                                  '${holding.amount.toStringAsFixed(6)} ${coin.symbol}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: 'Ortalama Alış Fiyatı',
                              value:
                                  '\$${holding.avgBuyPrice.toStringAsFixed(4)}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: 'Toplam Yatırılan',
                              value: '\$${investedUsd.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: 'Şu An Satarsan (Güncel Değer)',
                              value: '\$${ownedValueUsd.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: 'Kâr/Zarar',
                              value: '${profitUsd >= 0 ? '+' : ''}'
                                  '\$${profitUsd.toStringAsFixed(2)} '
                                  '(${profitUsd >= 0 ? '+' : ''}${profitPct.toStringAsFixed(2)}%)',
                              valueColor: profitUsd >= 0
                                  ? AppColors.positive
                                  : AppColors.negative,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (transactions.isNotEmpty) ...[
                      const Text(
                        'İşlem Geçmişi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...transactions.map(
                        (tx) => _TransactionTile(
                          transaction: tx,
                          symbol: coin.symbol,
                        ),
                      ),
                    ],
                  ],
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Portföyümdeki Durumum" kartındaki etiket + değer satırı.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// İşlem geçmişindeki tek bir alım/satım satırı.
class _TransactionTile extends StatelessWidget {
  final CoinTransaction transaction;
  final String symbol;

  const _TransactionTile({
    required this.transaction,
    required this.symbol,
  });

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}  '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isBuy = transaction.isBuy;
    final Color badgeColor = isBuy ? AppColors.positive : AppColors.negative;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isBuy ? 'Alış' : 'Satış',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.amount.toStringAsFixed(6)} $symbol  •  '
                  '\$${transaction.price.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${transaction.totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}