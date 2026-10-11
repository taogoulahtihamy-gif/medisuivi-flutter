import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'design_system.dart';
export 'design_system.dart';

abstract final class Palette {
  static const canvas = Color(0xFFF8FCF9);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF183A2E);
  static const muted = Color(0xFF627A6E);
  // Couleurs de marque approuvées : Forest Code et Mint Fog.
  static const forest = Color(0xFF075E46);
  static const mintFog = Color(0xFFE8FFF2);
  // Alias conservés pour les composants existants.
  static const teal = forest;
  static const deepForest = AppColors.deepForest;
  static const tealDark = Color(0xFF064B39);
  static const tealSoft = mintFog;
  static const border = Color(0xFFDDEEE4);
  static const amber = Color(0xFFF0B25F);
  static const amberSoft = Color(0xFFFFF3E3);
  static const danger = Color(0xFFAE4F4F);
  static const navy = Color(0xFF064B39);
  static const aqua = Color(0xFFD8F8E6);
  static const blueSoft = Color(0xFFEAF7EF);
  static const lavenderSoft = Color(0xFFF1F8EB);
}

abstract final class MediTheme {
  static ThemeData light() {
    const radius = 22.0;
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.teal,
      primary: Palette.teal,
      surface: Palette.white,
      brightness: Brightness.light,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.canvas,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.canvas,
        foregroundColor: Palette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: AppTypography.apply(base.textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: MedicalPageTransitions(),
        TargetPlatform.iOS: MedicalCupertinoTransitions(),
      }),
      chipTheme: ChipThemeData(
          backgroundColor: Palette.white,
          selectedColor: Palette.mintFog,
          side: const BorderSide(color: Palette.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      cardTheme: CardThemeData(
        color: Palette.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Palette.border),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Palette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Palette.teal, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.teal,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Palette.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
      dividerColor: Palette.border,
      iconTheme: const IconThemeData(color: Palette.ink),
      cupertinoOverrideTheme:
          const CupertinoThemeData(primaryColor: Palette.teal),
    );
  }
}

abstract final class AppTheme {
  static ThemeData light() => MediTheme.light();
}
