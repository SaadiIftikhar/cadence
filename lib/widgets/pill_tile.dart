import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import 'segmented_border.dart';
import 'tappable_icon.dart';

/// The stadium row used for steps and reminders throughout the designs.
///
/// Always outlined: the outline is what carries meaning here, either plainly
/// or split into one arc per step.
class PillTile extends StatelessWidget {
  const PillTile({
    super.key,
    required this.label,
    this.iconKey,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.dimmed = false,
    this.subtitle,
    this.progress,
    this.outlineColor,
    this.onIconTap,
  });

  /// Makes the leading icon its own tap target, so a row can offer a second
  /// action without a menu. Tapping elsewhere still runs [onTap].
  final VoidCallback? onIconTap;

  /// Overrides the outline colour. A single step has no segments to fill, so
  /// the whole outline turns green when it is done.
  final Color? outlineColor;

  final String label;
  final String? subtitle;
  final String? iconKey;

  /// When set and covering more than one step, the outline is drawn as one
  /// arc per step with the completed ones filled.
  final ({int done, int total})? progress;
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final foreground = dimmed
        ? AppColors.onSurfaceVariant.withValues(alpha: 0.6)
        : AppColors.onSurface;

    final segments = progress;
    final showSegments = segments != null && segments.total > 1;

    final tile = Material(
      color: Colors.transparent,
      // The painter supplies the outline when segmented, so drop the plain one.
      shape: showSegments
          ? AppShapes.pill
          : StadiumBorder(
              side: BorderSide(
                color: outlineColor ?? AppColors.outline,
                // A coloured outline stands in for the segmented arcs, so it
                // carries their weight rather than a hairline's.
                width: outlineColor == null
                    ? 1
                    : SegmentedProgressBorder.strokeWidth,
              ),
            ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          child: Row(
            children: [
              if (onIconTap == null) ...[
                Icon(IconCatalog.resolve(iconKey), size: 26, color: foreground),
                const SizedBox(width: 22),
              ] else ...[
                TappableIcon(
                  iconKey: iconKey,
                  onTap: onIconTap!,
                  semanticLabel: 'Change step icon',
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        color: foreground,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );

    if (!showSegments) return tile;
    return SegmentedProgressBorder(
      done: segments.done,
      total: segments.total,
      shape: AppShapes.pill,
      child: tile,
    );
  }
}
