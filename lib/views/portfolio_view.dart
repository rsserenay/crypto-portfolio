import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import 'widgets/buy_sheet.dart';

class PortfolioView extends StatelessWidget {
  const PortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    final PortfolioController controller = Get.find<PortfolioController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Portföyüm')),
      body: RefreshIndicator(
        onRefresh: controller.onPullToRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _TotalBalanceCard(controller: controller),
            const SizedBox(height: 20),
            const Text('Varlıklarım',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoading.value &&
                  controller.portfolioItems.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.portfolioItems.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Henüz coin satın almadınız.\nPiyasalar sekmesinden bir coine dokunun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: controller.portfolioItems.map((item) {
                  return Dismissible(
                    key: ValueKey(item.coin.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Coini Sil'),
                          content: Text(
                            '${item.coin.name} portföyünüzden silinsin mi?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) {
                      controller.deleteCoin(item.coin.id);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          Get.bottomSheet(
                            BuySheet(
                              coin: item.coin,
                              isSelling: true,
                            ),
                            backgroundColor: Colors.white,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundImage: item.coin.image.isNotEmpty
                              ? NetworkImage(item.coin.image)
                              : null,
                        ),
                        title: Text(item.coin.name),
                        subtitle: Text(
                          '${item.amount} ${item.coin.symbol}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.valueUsd.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.profitPercentage >= 0 ? '+' : ''}'
                              '${item.profitPercentage.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: item.profitPercentage >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final PortfolioController controller;

  const _TotalBalanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Toplam Cüzdan Değeri',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Obx(
            () {
              final profit = controller.totalProfitUsd.value;
              final percentage = controller.totalProfitPercentage;

              return Text(
                '${profit >= 0 ? '+' : ''}'
                '\$${profit.toStringAsFixed(2)} '
                '(${percentage.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          Obx(
            () => Text(
              '\$${controller.totalBalanceUsd.value.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
