import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Draws the child's outline as one arc per step, filling the arcs that are
/// done. Reading the border tells you how many steps remain without relying on
/// colour, which a red-to-green ramp could not do.
class SegmentedProgressBorder extends StatelessWidget {
  const SegmentedProgressBorder({
    super.key,
    required this.done,
    required this.total,
    required this.shape,
    required this.child,
  });

  final int done;
  final int total;

  /// The same shape the child is clipped to. Tracing it directly means the
  /// arcs follow a pill, a rounded image card, or anything else without the
  /// two definitions ever drifting apart.
  final ShapeBorder shape;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _SegmentedBorderPainter(
        done: done,
        total: total,
        shape: shape,
      ),
      child: child,
    );
  }
}

class _SegmentedBorderPainter extends CustomPainter {
  _SegmentedBorderPainter({
    required this.done,
    required this.total,
    required this.shape,
  });

  final int done;
  final int total;
  final ShapeBorder shape;

  static const _stroke = 2.5;
  static const _maxGap = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final bounds = (Offset.zero & size).deflate(_stroke / 2);
    if (bounds.width <= 0 || bounds.height <= 0) return;

    final metrics = shape.getOuterPath(bounds).computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    if (metric.length <= 0) return;

    final segment = metric.length / total;
    // The gap shrinks as segments multiply, so a long routine degrades into a
    // near-solid ring instead of a dotted mess.
    final gap = math.min(_maxGap, segment * 0.28);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (var i = 0; i < total; i++) {
      final start = i * segment + gap / 2;
      final end = (i + 1) * segment - gap / 2;
      if (end <= start) continue;

      paint.color = i < done ? AppColors.success : AppColors.outlineDim;
      canvas.drawPath(metric.extractPath(start, end), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedBorderPainter old) =>
      old.done != done || old.total != total || old.shape != shape;
}
