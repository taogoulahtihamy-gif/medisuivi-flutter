import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../models/medical_models.dart';
import 'medical_ui.dart';

class TemperatureTrend extends StatelessWidget {
  const TemperatureTrend({super.key, required this.visits});
  final List<Visit> visits;
  @override
  Widget build(BuildContext context) {
    final points = visits
        .where((v) => v.temperature != null && v.temperature!.isFinite)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (points.length < 2) return const SizedBox.shrink();
    return PremiumCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Évolution de la température',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Mesures enregistrées · °C · sans interprétation',
          style: TextStyle(fontSize: 12, color: Palette.muted)),
      const SizedBox(height: 16),
      ExcludeSemantics(
          child: SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(painter: _TrendPainter(points)))),
      const SizedBox(height: 12),
      Wrap(spacing: 20, runSpacing: 8, children: [
        for (final p in points)
          Text('${shortDate(p.date)} : ${p.temperature!.toStringAsFixed(1)} °C',
              style: const TextStyle(fontSize: 12))
      ]),
    ]));
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points);
  final List<Visit> points;
  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.temperature!).toList();
    final low = values.reduce((a, b) => a < b ? a : b) - .2;
    final high = values.reduce((a, b) => a > b ? a : b) + .2;
    final first = points.first.date.millisecondsSinceEpoch;
    final span = points.last.date.millisecondsSinceEpoch - first;
    final offsets = [
      for (var i = 0; i < points.length; i++)
        Offset(
            6 +
                (size.width - 12) *
                    (span == 0
                        ? i / (points.length - 1)
                        : (points[i].date.millisecondsSinceEpoch - first) /
                            span),
            6 + (size.height - 12) * (1 - (values[i] - low) / (high - low)))
    ];
    final grid = Paint()
      ..color = Palette.border
      ..strokeWidth = 1;
    for (final y in [6.0, size.height / 2, size.height - 6]) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), grid);
    }
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = Palette.forest
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, Paint()..color = Palette.forest);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}
