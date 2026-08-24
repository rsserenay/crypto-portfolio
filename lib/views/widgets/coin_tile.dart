import 'package:flutter/material.dart';
import '../../models/coin_model.dart';

/// Saf UI widget'ı. İçinde hesaplama/filtreleme YOKTUR, sadece verilen
/// CoinModel'i ekrana basar.
class CoinTile extends StatelessWidget {
  final CoinModel coin;
  final VoidCallback onTap;

  const CoinTile({super.key, required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isUp = coin.priceChangePercentage24h >= 0;
    final Color changeColor = isUp ? Colors.green : Colors.red;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        backgroundImage: coin.image.isNotEmpty
            ? NetworkImage(coin.image)
            : null,
        child: coin.image.isEmpty ? Text(coin.symbol.characters.first) : null,
      ),
      title: Text(coin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(coin.symbol),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$${coin.currentPrice.toStringAsFixed(coin.currentPrice < 1 ? 6 : 2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${isUp ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
            style: TextStyle(color: changeColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
