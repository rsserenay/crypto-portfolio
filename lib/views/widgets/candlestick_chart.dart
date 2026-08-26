import 'package:flutter/material.dart';
import '../../models/coin_model.dart';
import '../../theme/app_colors.dart';

/// Verilen mum (candle) listesini çizen saf UI widget'ı.
/// Zaman aralığı seçimi, veri çekme gibi mantık burada YOKTUR;
/// bu widget sadece elindeki listeyi çizer.
class CandlestickChart extends StatelessWidget {
  final List<CandleModel> candles;

  const CandlestickChart({super.key, required this.candles});

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return const Center(
        child: Text(
          'Grafik verisi yok',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return CustomPaint(
      painter: _CandlestickPainter(candles: candles),
      size: Size.infinite,
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<CandleModel> candles;

  _CandlestickPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    final double maxHigh =
        candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final double minLow =
        candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final double range = (maxHigh - minLow) == 0 ? 1 : (maxHigh - minLow);

    final double slotWidth = size.width / candles.length;
    final double candleWidth = (slotWidth * 0.6).clamp(1.5, 14.0);

    double yFor(double price) {
      final double normalized = (price - minLow) / range;
      return size.height - (normalized * size.height);
    }

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final double centerX = (i * slotWidth) + (slotWidth / 2);

      final Color color =
          candle.isBullish ? AppColors.positive : AppColors.negative;

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(centerX, yFor(candle.high)),
        Offset(centerX, yFor(candle.low)),
        wickPaint,
      );

      final double openY = yFor(candle.open);
      final double closeY = yFor(candle.close);
      final double bodyTop = openY < closeY ? openY : closeY;
      final double bodyBottom = openY < closeY ? closeY : openY;
      final double bodyHeight = (bodyBottom - bodyTop).clamp(1.5, double.infinity);

      final bodyPaint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - (candleWidth / 2),
            bodyTop,
            candleWidth,
            bodyHeight,
          ),
          const Radius.circular(1.5),
        ),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles;
  }
}
