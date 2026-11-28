import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum PipShape { circle, triangle }

/// Full groups of five and the loose icons left over.
({int groups, int loose}) tallySplit(int count) =>
    (groups: count ~/ 5, loose: count % 5);

/// [count] icons on one line, tallied in fives: each five is four small icons
/// in an oval with a slash through it. Shrinks to fit instead of wrapping.
class CountPips extends StatelessWidget {
  const CountPips({
    super.key,
    required this.count,
    required this.shape,
    this.color = mendingInk,
    this.maxSize = 18,
  });

  final int count;
  final PipShape shape;
  final Color color;
  final double maxSize;

  static const _groupWidth = 2.5;
  static const _gap = 0.3;

  @override
  Widget build(BuildContext context) {
    final split = tallySplit(count);
    final items = split.groups + split.loose;
    final units =
        split.groups * _groupWidth +
        split.loose +
        math.max(0, items - 1) * _gap;
    return Semantics(
      label: '$count',
      child: SizedBox(
        height: maxSize,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = units == 0
                ? maxSize
                : math.min(maxSize, constraints.maxWidth / units);
            return CustomPaint(
              size: Size(units * size, maxSize),
              painter: _PipPainter(
                groups: split.groups,
                loose: split.loose,
                size: size,
                shape: shape,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({
    required this.groups,
    required this.loose,
    required this.size,
    required this.shape,
    required this.color,
  });

  final int groups;
  final int loose;
  final double size;
  final PipShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, size * 0.09);
    final cy = canvasSize.height / 2;
    var x = 0.0;

    for (var g = 0; g < groups; g++) {
      final width = size * CountPips._groupWidth;
      final oval = Rect.fromLTWH(x, cy - size / 2, width, size);
      canvas.drawOval(oval.deflate(stroke.strokeWidth / 2), stroke);
      final small = size * 0.42;
      final step = (width - size * 0.4) / 4;
      for (var i = 0; i < 4; i++) {
        _icon(
          canvas,
          Offset(x + size * 0.2 + step * (i + 0.5), cy),
          small,
          fill,
        );
      }
      canvas.drawLine(
        Offset(x + width * 0.18, cy + size * 0.55),
        Offset(x + width * 0.82, cy - size * 0.55),
        stroke,
      );
      x += width + size * CountPips._gap;
    }

    for (var i = 0; i < loose; i++) {
      _icon(canvas, Offset(x + size / 2, cy), size * 0.8, fill);
      x += size * (1 + CountPips._gap);
    }
  }

  void _icon(Canvas canvas, Offset center, double extent, Paint paint) {
    switch (shape) {
      case PipShape.circle:
        canvas.drawCircle(center, extent / 2, paint);
      case PipShape.triangle:
        final h = extent * math.sqrt(3) / 2;
        final path = Path()
          ..moveTo(center.dx, center.dy - h * 2 / 3)
          ..lineTo(center.dx + extent / 2, center.dy + h / 3)
          ..lineTo(center.dx - extent / 2, center.dy + h / 3)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PipPainter old) =>
      old.groups != groups ||
      old.loose != loose ||
      old.size != size ||
      old.shape != shape ||
      old.color != color;
}
