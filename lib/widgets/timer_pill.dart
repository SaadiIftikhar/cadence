import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/duration_format.dart';
import 'segmented_border.dart';

/// A step's countdown, drawn as a pill whose border fills with green as time
/// elapses — the same visual language as a finished step's outline and a
/// routine's segmented progress, rather than a shape of its own.
///
/// The border is one continuous ring, not segments: a single timer is one
/// continuous quantity, unlike a routine's discrete steps.
class TimerPill extends StatelessWidget {
  const TimerPill({
    super.key,
    required this.remaining,
    required this.total,
  });

  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = total.inSeconds;
    final fraction = totalSeconds <= 0
        ? 0.0
        : (1 - remaining.inSeconds / totalSeconds).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction),
      // Matches the ticker's own one-second cadence rather than the app's
      // usual transition timings: the ring should visibly creep for the same
      // second the number just changed, not snap to the new value.
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
      builder: (context, value, child) => CustomPaint(
        foregroundPainter: _TimerRingPainter(fraction: value),
        child: child,
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 168, minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        alignment: Alignment.center,
        child: Text(
          formatDuration(remaining),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
            fontFeatures: [FontFeature.tabularFigures()],
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({required this.fraction});

  /// 0 at the timer's full length, 1 once it has run out.
  final double fraction;

  static const _stroke = SegmentedProgressBorder.strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(_stroke / 2);
    if (bounds.width <= 0 || bounds.height <= 0) return;

    final path = AppShapes.pill.getOuterPath(bounds);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    if (metric.length <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    paint.color = AppColors.outline;
    canvas.drawPath(path, paint);

    if (fraction <= 0) return;
    paint.color = AppColors.success;
    final filled = fraction >= 1
        ? path
        : metric.extractPath(0, metric.length * fraction);
    canvas.drawPath(filled, paint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.fraction != fraction;
}
