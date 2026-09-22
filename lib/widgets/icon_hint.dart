import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A one-off note pointing up at the icon beside a title field, explaining
/// that the icon is also the button that changes it.
///
/// Shown once for the whole app rather than once per screen: the point is
/// learned the first time, and a hint that keeps reappearing stops being a
/// hint and becomes clutter.
class IconHint extends StatelessWidget {
  const IconHint({
    super.key,
    required this.onDismiss,
    this.arrowInset = 30,
  });

  final VoidCallback onDismiss;

  /// Distance from the left edge to the arrow's tip, lined up with the icon
  /// it points at.
  final double arrowInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: arrowInset),
            child: CustomPaint(
              size: const Size(18, 9),
              painter: _ArrowPainter(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tap the icon to change it',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
