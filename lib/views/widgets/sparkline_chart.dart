import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Verilen fiyat listesini küçük bir çizgi grafik olarak çizer.
/// Saf UI widget'ı: içeride hiçbir hesaplama/filtreleme mantığı yoktur,
/// sadece dışarıdan aldığı listeyi normalize edip çizer.
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final double strokeWidth;
  final bool filled;

  const SparklineChart({
    super.key,
    required this.data,
    this.lineColor = AppColors.positive,
    this.strokeWidth = 2,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        lineColor: lineColor,
        strokeWidth: strokeWidth,
        filled: filled,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final double strokeWidth;
  final bool filled;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.strokeWidth,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double minValue = data.reduce((a, b) => a < b ? a : b);
    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    final double range = (maxValue - minValue) == 0 ? 1 : (maxValue - minValue);

    final double stepX = size.width / (data.length - 1);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double normalized = (data[i] - minValue) / range;
      final double y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (filled) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: 0.25), lineColor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.filled != filled;
  }
}
