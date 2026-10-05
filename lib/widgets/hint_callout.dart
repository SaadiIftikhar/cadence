import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// A one-off note pointing up at the control above it, explaining something
/// the control cannot say for itself.
///
/// Each kind is shown once for the whole app rather than once per screen: the
/// point is learned the first time, and a hint that keeps reappearing stops
/// being a hint and becomes clutter.
class HintCallout extends StatelessWidget {
  const HintCallout({
    super.key,
    required this.message,
    required this.onDismiss,
    this.arrowInset = 30,
  });

  final String message;
  final VoidCallback onDismiss;

  /// Distance from the left edge to the arrow's tip, lined up with whatever
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
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
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
                  child: Text(AppLocalizations.of(context).actionGotIt),
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
