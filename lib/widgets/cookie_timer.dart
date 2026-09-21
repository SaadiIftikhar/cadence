import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

String formatDuration(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final h = total.inHours;
  final m = total.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// The scalloped "cookie" countdown from the timer mockup. It turns slowly
/// while running, which is the only motion cue the design gives.
class CookieTimer extends StatefulWidget {
  const CookieTimer({
    super.key,
    required this.remaining,
    required this.running,
    this.size = 230,
  });

  final Duration remaining;
  final bool running;
  final double size;

  @override
  State<CookieTimer> createState() => _CookieTimerState();
}

class _CookieTimerState extends State<CookieTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    if (widget.running) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant CookieTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.running && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = widget.remaining <= Duration.zero;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _spin,
            builder: (context, child) => Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: child,
            ),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _CookiePainter(
                color: finished ? AppColors.accentPink : const Color(0xFFF5EFFA),
              ),
            ),
          ),
          Text(
            formatDuration(widget.remaining),
            style: TextStyle(
              fontSize: widget.size * 0.20,
              fontWeight: FontWeight.w600,
              color: finished ? AppColors.onAccentPink : AppColors.onPrimary,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CookiePainter extends CustomPainter {
  _CookiePainter({required this.color});

  final Color color;

  static const lobes = 10;
  static const amplitude = 0.09;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 / (1 + amplitude);
    final path = Path();

    const samples = 720;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples * 2 * math.pi;
      final r = baseRadius * (1 + amplitude * math.cos(lobes * t));
      final point = center + Offset(math.cos(t) * r, math.sin(t) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(covariant _CookiePainter old) => old.color != color;
}
