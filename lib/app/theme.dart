import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Palette clinique : vert utilisé comme accent, neutres pour la lecture.
/// Les anciens tokens sont conservés pour la compatibilité des écrans V0.
abstract final class Palette {
  static const canvas = Color(0xFFF7F9F8);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF21352F);
  static const muted = Color(0xFF687A73);
  static const border = Color(0xFFE2EAE5);
  static const forest = Color(0xFF16624F);
  static const teal = forest;
  static const tealDark = Color(0xFF10513F);
  static const tealSoft = Color(0xFFEDF6F0);
  static const mintFog = tealSoft;
  static const navy = Color(0xFF193F34);
  static const charcoal = ink;
  static const charcoalSoft = Color(0xFF304D42);
  static const canvasEditorial = canvas;
  static const aqua = tealSoft;
  static const blueSoft = Color(0xFFF1F5F3);
  static const lavenderSoft = Color(0xFFF1F5F3);
  static const amber = Color(0xFF805F37);
  static const amberSoft = Color(0xFFF7F4ED);
  static const danger = Color(0xFF9C4247);

  // Alias transitoires (historique) : ne pas utiliser pour les nouveaux écrans.
  static const night = navy;
  static const laser = forest;
  static const laserMuted = muted;
  static const laserBorder = border;
  static const laserVeil = tealSoft;
}

abstract final class MediTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Palette.forest,
      onPrimary: Palette.white,
      primaryContainer: Palette.tealSoft,
      onPrimaryContainer: Palette.ink,
      secondary: Palette.navy,
      onSecondary: Palette.white,
      secondaryContainer: Palette.tealSoft,
      onSecondaryContainer: Palette.ink,
      tertiary: Palette.forest,
      onTertiary: Palette.white,
      error: Palette.danger,
      onError: Palette.white,
      surface: Palette.white,
      onSurface: Palette.ink,
      onSurfaceVariant: Palette.muted,
      outline: Palette.border,
      shadow: Palette.ink,
      inverseSurface: Palette.ink,
      onInverseSurface: Palette.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
    );
    // Polices système : SF Pro sur iOS, Roboto sur Android.
    final text = const TextTheme(
      headlineLarge: TextStyle(fontSize: 30, height: 1.14,
        fontWeight: FontWeight.w700, letterSpacing: -0.8),
      headlineMedium: TextStyle(fontSize: 26, height: 1.2,
        fontWeight: FontWeight.w700, letterSpacing: -0.6),
      titleLarge: TextStyle(fontSize: 21, height: 1.3,
        fontWeight: FontWeight.w700, letterSpacing: -0.35),
      titleMedium: TextStyle(fontSize: 17, height: 1.33,
        fontWeight: FontWeight.w600, letterSpacing: -0.2),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45,
        fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 13, height: 1.38),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    ).apply(bodyColor: Palette.ink, displayColor: Palette.ink);

    return base.copyWith(
      scaffoldBackgroundColor: Palette.canvas,
      colorScheme: scheme,
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.canvas,
        foregroundColor: Palette.ink,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: Palette.ink,
          fontSize: 19, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Palette.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: const BorderSide(color: Palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Palette.muted, fontSize: 14),
        labelStyle: const TextStyle(color: Palette.muted, fontSize: 14),
        prefixIconColor: Palette.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Palette.forest, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.forest,
          foregroundColor: Palette.white,
          elevation: 0,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.forest,
          foregroundColor: Palette.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.forest,
          side: const BorderSide(color: Palette.border),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.forest,
          textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      iconTheme: const IconThemeData(color: Palette.ink),
      dividerColor: Palette.border,
      chipTheme: ChipThemeData(
        backgroundColor: Palette.white,
        selectedColor: Palette.tealSoft,
        side: const BorderSide(color: Palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(color: Palette.ink,
          fontSize: 13, fontWeight: FontWeight.w600),
        checkmarkColor: Palette.forest,
        showCheckmark: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.navy,
        contentTextStyle: TextStyle(color: Palette.white),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Palette.forest,
        selectionColor: Palette.tealSoft,
        selectionHandleColor: Palette.forest,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.white,
        modalBackgroundColor: Palette.white,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: Palette.forest),
    );
  }
}
