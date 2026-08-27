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
    // Size.infinite yerine LayoutBuilder ile gerçek/sonlu boyutu alıyoruz.
    // Bazı cihaz/emulator'lerde sınırsız (infinite) boyut talebi native
    // render motorunda geçersiz bir tuval isteğine ve çökmeye yol açabiliyor.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;

        return CustomPaint(
          painter: _CandlestickPainter(candles: candles),
          size: Size(width, height),
        );
      },
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<CandleModel> candles;

  _CandlestickPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    // Güvenlik: sıfır/negatif/NaN boyutta hiçbir şey çizme.
    if (candles.isEmpty ||
        size.width <= 0 ||
        size.height <= 0 ||
        size.width.isNaN ||
        size.height.isNaN) {
      return;
    }

    final double maxHigh =
        candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final double minLow =
        candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final double rawRange = maxHigh - minLow;
    final double range = (rawRange == 0 || rawRange.isNaN) ? 1 : rawRange;

    final double slotWidth = size.width / candles.length;
    if (slotWidth <= 0 || slotWidth.isNaN) return;

    final double candleWidth = (slotWidth * 0.6).clamp(1.5, 14.0);

    double yFor(double price) {
      final double normalized = (price - minLow) / range;
      final double clamped = normalized.isNaN ? 0 : normalized.clamp(0.0, 1.0);
      return size.height - (clamped * size.height);
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
      double bodyHeight = bodyBottom - bodyTop;
      if (bodyHeight.isNaN || bodyHeight < 1.5) bodyHeight = 1.5;

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