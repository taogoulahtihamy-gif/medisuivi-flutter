import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Identité unique de MediSuivi.
/// Aucune autre teinte source : uniquement Night Shift et Laser Lemon.
/// Les couleurs translucides conservent le RGB de Laser Lemon.
abstract final class Palette {
  static const night = Color(0xFF10131A);
  static const laser = Color(0xFFEFFF4F);
  static const laserMuted = Color(0xB3EFFF4F);
  static const laserBorder = Color(0x50EFFF4F);
  static const laserVeil = Color(0x1AEFFF4F);

  // Compatibilité avec les écrans de la V0, sans introduire de couleurs.
  static const canvas = night;
  static const canvasEditorial = night;
  static const charcoal = night;
  static const charcoalSoft = laserVeil;
  static const navy = night;
  static const white = night;
  static const ink = laser;
  static const muted = laserMuted;
  static const teal = laser;
  static const tealDark = night;
  static const tealSoft = laserVeil;
  static const forest = laser;
  static const mintFog = laserVeil;
  static const border = laserBorder;
  static const amber = laser;
  static const amberSoft = laserVeil;
  static const danger = laser;
  static const aqua = laserVeil;
  static const blueSoft = laserVeil;
  static const lavenderSoft = laserVeil;
}

abstract final class MediTheme {
  static ThemeData light() {
    // Nom de méthode conservé pour compatibilité, le design est exclusivement sombre.
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Palette.laser,
      onPrimary: Palette.night,
      primaryContainer: Palette.night,
      onPrimaryContainer: Palette.laser,
      primaryFixed: Palette.laser,
      primaryFixedDim: Palette.laser,
      onPrimaryFixed: Palette.night,
      onPrimaryFixedVariant: Palette.night,
      secondary: Palette.laser,
      onSecondary: Palette.night,
      secondaryContainer: Palette.night,
      onSecondaryContainer: Palette.laser,
      secondaryFixed: Palette.laser,
      secondaryFixedDim: Palette.laser,
      onSecondaryFixed: Palette.night,
      onSecondaryFixedVariant: Palette.night,
      tertiary: Palette.laser,
      onTertiary: Palette.night,
      tertiaryContainer: Palette.night,
      onTertiaryContainer: Palette.laser,
      tertiaryFixed: Palette.laser,
      tertiaryFixedDim: Palette.laser,
      onTertiaryFixed: Palette.night,
      onTertiaryFixedVariant: Palette.night,
      error: Palette.laser,
      onError: Palette.night,
      errorContainer: Palette.night,
      onErrorContainer: Palette.laser,
      surface: Palette.night,
      onSurface: Palette.laser,
      surfaceDim: Palette.night,
      surfaceBright: Palette.night,
      surfaceContainerLowest: Palette.night,
      surfaceContainerLow: Palette.night,
      surfaceContainer: Palette.night,
      surfaceContainerHigh: Palette.night,
      surfaceContainerHighest: Palette.night,
      onSurfaceVariant: Palette.laserMuted,
      outline: Palette.laserBorder,
      outlineVariant: Palette.laserBorder,
      shadow: Palette.night,
      scrim: Palette.night,
      inverseSurface: Palette.laser,
      onInverseSurface: Palette.night,
      inversePrimary: Palette.night,
      surfaceTint: Palette.laser,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: Palette.night,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.night,
        foregroundColor: Palette.laser,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Palette.laser,
        displayColor: Palette.laser,
      ),
      iconTheme: const IconThemeData(color: Palette.laser),
      cardTheme: CardThemeData(
        color: Palette.night,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Palette.laserBorder),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.laserVeil,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Palette.laserMuted),
        labelStyle: const TextStyle(color: Palette.laserMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Palette.laserBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Palette.laserBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Palette.laser, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.laser,
          foregroundColor: Palette.night,
          elevation: 0,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.laser,
          foregroundColor: Palette.night,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.laser,
          side: const BorderSide(color: Palette.laserBorder),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Palette.laser),
      ),
      dividerColor: Palette.laserBorder,
      chipTheme: ChipThemeData(
        backgroundColor: Palette.night,
        selectedColor: Palette.laser,
        side: const BorderSide(color: Palette.laserBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(
          color: Palette.laser, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
          color: Palette.night, fontWeight: FontWeight.w700),
        checkmarkColor: Palette.night,
        showCheckmark: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.laser,
        contentTextStyle: TextStyle(color: Palette.night),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Palette.laser,
        selectionColor: Palette.laserVeil,
        selectionHandleColor: Palette.laser,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.night,
        modalBackgroundColor: Palette.night,
      ),
      cupertinoOverrideTheme:
        const CupertinoThemeData(primaryColor: Palette.laser),
    );
  }
}
