import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';

/// An icon that is also a button.
///
/// The filled circle behind it is what says so: a bare icon sitting in a text
/// field or a row reads as decoration, and nobody tries tapping decoration.
class TappableIcon extends StatelessWidget {
  const TappableIcon({
    super.key,
    required this.iconKey,
    required this.onTap,
    this.semanticLabel = 'Choose icon',
    this.size = 26,
    this.color,
  });

  final String? iconKey;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceFilled,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            IconCatalog.resolve(iconKey),
            size: size,
            color: color ?? AppColors.onSurface,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
