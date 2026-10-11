import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class Palette {
  static const canvas = Color(0xFFF5F7F6);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17323A);
  static const muted = Color(0xFF687A80);
  static const teal = Color(0xFF146C70);
  static const tealDark = Color(0xFF0F5559);
  static const tealSoft = Color(0xFFE6F2F0);
  static const border = Color(0xFFE1E9E7);
  static const amber = Color(0xFFF0B25F);
  static const amberSoft = Color(0xFFFFF3E3);
  static const danger = Color(0xFFAE4F4F);
}

abstract final class MediTheme {
  static ThemeData light() {
    const radius = 18.0;
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.teal,
      primary: Palette.teal,
      surface: Palette.white,
      brightness: Brightness.light,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.canvas,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.canvas,
        foregroundColor: Palette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Palette.ink,
        displayColor: Palette.ink,
      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Palette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Palette.teal, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.teal,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Palette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      dividerColor: Palette.border,
      cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: Palette.teal),
    );
  }
}
