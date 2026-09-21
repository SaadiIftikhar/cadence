import 'package:flutter/material.dart';

/// Shape of the image on a home card. The cropper locks to the same numbers,
/// so whatever is framed while cropping is exactly what the card shows.
const double kCardImageRatioX = 16;
const double kCardImageRatioY = 9;
const double kCardImageAspect = kCardImageRatioX / kCardImageRatioY;

/// Palette sampled from the design mockups.
class AppColors {
  static const background = Color(0xFF121316);
  static const surfaceLow = Color(0xFF1B1B1F);
  static const surfaceFilled = Color(0xFF2E2E33);
  static const surfaceRaised = Color(0xFF3A3A40);

  static const primary = Color(0xFFD0BCFF);
  static const onPrimary = Color(0xFF381E72);
  static const primaryDim = Color(0xFFC7B6EE);

  static const accentPink = Color(0xFFF7C8D2);
  static const onAccentPink = Color(0xFF3F1420);

  static const outline = Color(0xFFE4E1E6);
  static const outlineDim = Color(0xFF49454F);
  static const onSurface = Color(0xFFE6E1E5);
  static const onSurfaceVariant = Color(0xFFCAC4D0);
  static const danger = Color(0xFFF2B8B5);

  /// Deliberately off-palette: completed steps need to read as done at a
  /// glance, which the lavender primary cannot do next to other lavender.
  static const success = Color(0xFF6EDC9B);
}

/// Every interactive surface in the mockups is either a stadium pill or a
/// 28dp rounded rectangle, so the shapes are centralised here.
class AppShapes {
  static const pill = StadiumBorder();
  static final card = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primary,
    onPrimaryContainer: AppColors.onPrimary,
    secondary: AppColors.primaryDim,
    onSecondary: AppColors.onPrimary,
    tertiary: AppColors.accentPink,
    onTertiary: AppColors.onAccentPink,
    tertiaryContainer: AppColors.accentPink,
    onTertiaryContainer: AppColors.onAccentPink,
    surface: AppColors.background,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surfaceLow,
    surfaceContainer: AppColors.surfaceFilled,
    surfaceContainerHigh: AppColors.surfaceRaised,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineDim,
    error: AppColors.danger,
    onError: Color(0xFF601410),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
      actionsIconTheme: IconThemeData(color: AppColors.onSurface, size: 26),
      titleTextStyle: TextStyle(
        color: AppColors.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceFilled,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: AppShapes.card,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(40)),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(40)),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(40)),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      floatingLabelStyle: const TextStyle(color: AppColors.onSurface),
      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      prefixIconColor: AppColors.onSurface,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outline),
        shape: AppShapes.pill,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: AppShapes.pill,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: AppShapes.pill,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF17171A);
        return AppColors.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFFF3EDFF);
        return AppColors.surfaceRaised;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return AppColors.onSurfaceVariant;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: const TextStyle(color: AppColors.onSurface),
      behavior: SnackBarBehavior.floating,
      shape: AppShapes.card,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLow,
      surfaceTintColor: Colors.transparent,
      shape: AppShapes.card,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
