import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MenuAction<T> {
  const MenuAction({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final T value;
}

/// Shows [actions] as labelled pills floating next to the widget behind
/// [anchorKey]. Dismisses on an outside tap or a back gesture, and flips to the
/// other side of the anchor when the preferred side has no room.
Future<T?> showAnchoredMenu<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required List<MenuAction<T>> actions,
  bool preferAbove = true,
}) {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return Future.value(null);

  final origin = box.localToGlobal(Offset.zero);
  final anchor = box.size;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 140),
    transitionBuilder: (ctx, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    pageBuilder: (ctx, _, _) {
      final screen = MediaQuery.of(ctx).size;
      const gap = 12.0;
      const spacing = 12.0;
      const pillHeight = 56.0;

      final menuHeight =
          actions.length * pillHeight + (actions.length - 1) * spacing;
      final needed = menuHeight + gap + 24;
      final spaceAbove = origin.dy;
      final spaceBelow = screen.height - (origin.dy + anchor.height);

      var above = preferAbove;
      if (above && spaceAbove < needed && spaceBelow >= needed) above = false;
      if (!above && spaceBelow < needed && spaceAbove >= needed) above = true;

      return Stack(
        children: [
          Positioned(
            right: (screen.width - origin.dx - anchor.width)
                .clamp(12.0, screen.width - 12.0),
            top: above ? null : origin.dy + anchor.height + gap,
            bottom: above ? screen.height - origin.dy + gap : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: spacing),
                  ActionPill(
                    icon: actions[i].icon,
                    label: actions[i].label,
                    onTap: () => Navigator.pop(ctx, actions[i].value),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

class ActionPill extends StatelessWidget {
  const ActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: AppShapes.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: AppColors.onPrimary),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
