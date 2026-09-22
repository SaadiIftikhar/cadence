import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/duration_format.dart';
import 'segmented_border.dart';

/// How much of the ring is still lit: 1 at the timer's full length, 0 once it
/// has run out. A total of zero is a step with no timer, which lights nothing.
double timerRingFraction(Duration remaining, Duration total) {
  final totalSeconds = total.inSeconds;
  if (totalSeconds <= 0) return 0;
  return (remaining.inSeconds / totalSeconds).clamp(0.0, 1.0);
}

/// A step's countdown, drawn as a pill whose border starts fully lit and
/// drains away as the time runs down, so what is left on the ring is what is
/// left on the clock.
///
/// The border is one continuous ring, not segments: a single timer is one
/// continuous quantity, unlike a routine's discrete steps.
class TimerPill extends StatelessWidget {
  const TimerPill({
    super.key,
    required this.remaining,
    required this.total,
    this.enabled = true,
  });

  final Duration remaining;
  final Duration total;

  /// A finished step's clock is inert: the ring drops its green and the
  /// number dims, so it reads as switched off alongside the controls beside
  /// it rather than as a timer waiting to be started.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: timerRingFraction(remaining, total)),
      // Matches the ticker's own one-second cadence rather than the app's
      // usual transition timings: the ring should visibly creep for the same
      // second the number just changed, not snap to the new value.
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
      builder: (context, value, child) => CustomPaint(
        foregroundPainter: _TimerRingPainter(fraction: value, enabled: enabled),
        child: child,
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 168, minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        alignment: Alignment.center,
        child: Text(
          formatDuration(remaining),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: enabled
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({required this.fraction, required this.enabled});

  /// 1 at the timer's full length, 0 once it has run out.
  final double fraction;

  final bool enabled;

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

    paint.color = enabled ? AppColors.outline : AppColors.outlineDim;
    canvas.drawPath(path, paint);

    if (!enabled || fraction <= 0) return;
    paint.color = AppColors.timerRing;
    final lit = fraction >= 1
        ? path
        : metric.extractPath(0, metric.length * fraction);
    canvas.drawPath(lit, paint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.fraction != fraction || old.enabled != enabled;
}
