import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/coin_model.dart';
import '../../controllers/portfolio_controller.dart';

/// Coine tıklandığında açılan satın alma formu.
/// Kendi başına hesaplama yapmaz; girilen miktarı doğrudan
/// PortfolioController.buyCoin'e devreder.
class BuySheet extends StatelessWidget {
  final CoinModel coin;

  const BuySheet({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final PortfolioController portfolioController =
        Get.find<PortfolioController>();
    final TextEditingController amountController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: coin.image.isNotEmpty
                    ? NetworkImage(coin.image)
                    : null,
              ),
              const SizedBox(width: 12),
              Text('${coin.name} Satın Al',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Güncel Fiyat: \$${coin.currentPrice.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Adet',
              border: OutlineInputBorder(),
              hintText: 'Örn: 0.5',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final double? amount =
                    double.tryParse(amountController.text.replaceAll(',', '.'));
                if (amount != null && amount > 0) {
                  portfolioController.buyCoin(coin.id, amount);
                  Get.back();
                  Get.snackbar('Başarılı', '${coin.symbol} portföyüne eklendi',
                      snackPosition: SnackPosition.BOTTOM);
                } else {
                  Get.snackbar('Hata', 'Geçerli bir miktar girin',
                      snackPosition: SnackPosition.BOTTOM);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Satın Al'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
