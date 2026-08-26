import 'package:flutter/material.dart';
import '../../models/coin_model.dart';
import '../../theme/app_colors.dart';
import 'sparkline_chart.dart';

/// Saf UI widget'ı. İçinde hesaplama/filtreleme YOKTUR, sadece verilen
/// CoinModel'i ekrana basar.
class CoinTile extends StatelessWidget {
  final CoinModel coin;
  final VoidCallback onTap;

  const CoinTile({super.key, required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isUp = coin.priceChangePercentage24h >= 0;
    final Color changeColor = isUp ? AppColors.positive : AppColors.negative;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.chipUnselected,
        backgroundImage: coin.image.isNotEmpty
            ? NetworkImage(coin.image)
            : null,
        child: coin.image.isEmpty ? Text(coin.symbol.characters.first) : null,
      ),
      title: Text(coin.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(coin.symbol,
          style: const TextStyle(color: AppColors.textSecondary)),
      trailing: SizedBox(
        width: 130,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (coin.sparklineData.length > 1)
              SizedBox(
                width: 46,
                height: 28,
                child: SparklineChart(
                  data: coin.sparklineData,
                  lineColor: changeColor,
                  strokeWidth: 1.5,
                ),
              ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${coin.currentPrice.toStringAsFixed(coin.currentPrice < 1 ? 6 : 2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isUp ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: changeColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
