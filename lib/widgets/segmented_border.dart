import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Draws the child's outline as one arc per step, filling the arcs that are
/// done. Reading the border tells you how many steps remain without relying on
/// colour, which a red-to-green ramp could not do.
///
/// On a cornered shape the arcs are cut at the corners, so four steps read as
/// top, right, bottom, left rather than four equal lengths that each straddle
/// a corner. A stadium has no corners to cut at, so it keeps equal arcs.
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

    final radius = _uniformRadius(bounds);
    final (path, cuts) = radius == null
        ? _evenPlan(bounds)
        : _cornerAlignedPlan(bounds, radius);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;
    if (length <= 0) return;

    // One gap width for every segment, taken from the shortest, so sides of
    // different lengths still look like they belong to the same ring.
    var shortest = double.infinity;
    for (var i = 0; i < total; i++) {
      final span = (cuts[i + 1] - cuts[i]) * length;
      if (span < shortest) shortest = span;
    }
    final gap = math.min(_maxGap, shortest * 0.28);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (var i = 0; i < total; i++) {
      final start = cuts[i] * length + gap / 2;
      final end = cuts[i + 1] * length - gap / 2;
      if (end <= start) continue;

      paint.color = i < done ? AppColors.success : AppColors.outlineDim;
      canvas.drawPath(metric.extractPath(start, end), paint);
    }
  }

  /// The corner radius when the shape is a rounded rectangle with four equal
  /// circular corners, and those corners are actually corners rather than a
  /// stadium's end caps. Null means fall back to even arcs.
  double? _uniformRadius(Rect bounds) {
    final s = shape;
    if (s is! RoundedRectangleBorder) return null;

    final r = s.borderRadius.resolve(TextDirection.ltr);
    final radius = r.topLeft.x;
    if (radius <= 0) return null;
    if (r.topLeft.y != radius) return null;
    if (r.topRight.x != radius || r.topRight.y != radius) return null;
    if (r.bottomLeft.x != radius || r.bottomLeft.y != radius) return null;
    if (r.bottomRight.x != radius || r.bottomRight.y != radius) return null;

    // A radius that eats the whole short side is a stadium in disguise.
    if (radius >= bounds.shortestSide / 2) return null;
    return radius;
  }

  (Path, List<double>) _evenPlan(Rect bounds) => (
        shape.getOuterPath(bounds),
        [for (var i = 0; i <= total; i++) i / total],
      );

  /// Walks the outline clockwise from the start of the top edge. Each side
  /// owns the corner that follows it, so a cut between two segments lands on
  /// a corner instead of part way along one.
  (Path, List<double>) _cornerAlignedPlan(Rect b, double r) {
    final path = Path()
      ..moveTo(b.left + r, b.top)
      ..lineTo(b.right - r, b.top)
      ..arcToPoint(Offset(b.right, b.top + r), radius: Radius.circular(r))
      ..lineTo(b.right, b.bottom - r)
      ..arcToPoint(Offset(b.right - r, b.bottom), radius: Radius.circular(r))
      ..lineTo(b.left + r, b.bottom)
      ..arcToPoint(Offset(b.left, b.bottom - r), radius: Radius.circular(r))
      ..lineTo(b.left, b.top + r)
      ..arcToPoint(Offset(b.left + r, b.top), radius: Radius.circular(r))
      ..close();

    final corner = math.pi * r / 2;
    final horizontal = b.width - 2 * r + corner;
    final vertical = b.height - 2 * r + corner;
    final sides = <double>[horizontal, vertical, horizontal, vertical];

    final starts = <double>[0];
    for (final side in sides) {
      starts.add(starts.last + side);
    }
    final perimeter = starts.last;

    final cuts = <double>[];
    if (total <= sides.length) {
      // Fewer steps than sides, so a step owns a run of whole sides.
      for (var i = 0; i < total; i++) {
        cuts.add(starts[(i * sides.length) ~/ total] / perimeter);
      }
    } else {
      // More steps than sides, so sides get subdivided by their length.
      final counts = _share(sides, total);
      for (var s = 0; s < sides.length; s++) {
        for (var k = 0; k < counts[s]; k++) {
          cuts.add((starts[s] + sides[s] * k / counts[s]) / perimeter);
        }
      }
    }
    cuts.add(1);
    return (path, cuts);
  }

  /// Spreads [n] segments across the sides, at least one each, the remainder
  /// going to whichever side is furthest below its share of the perimeter.
  List<int> _share(List<double> sides, int n) {
    final perimeter = sides.reduce((a, b) => a + b);
    final counts = List.filled(sides.length, 1);
    final ideal = [for (final side in sides) side / perimeter * n];

    for (var remaining = n - sides.length; remaining > 0; remaining--) {
      var best = 0;
      var bestGap = double.negativeInfinity;
      for (var i = 0; i < sides.length; i++) {
        final shortfall = ideal[i] - counts[i];
        if (shortfall > bestGap) {
          bestGap = shortfall;
          best = i;
        }
      }
      counts[best]++;
    }
    return counts;
  }

  @override
  bool shouldRepaint(covariant _SegmentedBorderPainter old) =>
      old.done != done || old.total != total || old.shape != shape;
}
