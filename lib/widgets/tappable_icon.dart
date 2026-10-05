import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
    this.semanticLabel,
    this.size = 26,
    this.color,
  });

  final String? iconKey;
  final VoidCallback onTap;

  /// Falls back to "Choose icon", which is what tapping one does everywhere
  /// except the step rows, where it retargets that step's own icon.
  final String? semanticLabel;
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
            semanticLabel:
                semanticLabel ?? AppLocalizations.of(context).chooseIcon,
          ),
        ),
      ),
    );
  }
}
