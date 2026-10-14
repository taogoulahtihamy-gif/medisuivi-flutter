import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Thème Nocturne Clinique — modes clair et sombre.
/// Source unique pour toute la coloration de l'application.
abstract final class ClinicalTheme {
  // ===== PALETTES =====
  static final ClinicalPalette _lightPalette = ClinicalPalette(
    brightness: Brightness.light,
    background: ClinicalColors.lightBackground,
    surface: ClinicalColors.lightSurface,
    surfaceElevated: ClinicalColors.lightSurfaceElevated,
    ink: ClinicalColors.lightInk,
    inkMuted: ClinicalColors.lightInkMuted,
    inkSubtle: ClinicalColors.lightInkSubtle,
    brandPrimary: ClinicalColors.lightBrandPrimary,
    brandPrimarySoft: ClinicalColors.lightBrandPrimarySoft,
    accentAmber: ClinicalColors.lightAccentAmber,
    accentAmberSoft: ClinicalColors.lightAccentAmberSoft,
    critical: ClinicalColors.lightCritical,
    criticalSoft: ClinicalColors.lightCriticalSoft,
    border: ClinicalColors.lightBorder,
    borderFocus: ClinicalColors.lightBorderFocus,
    shadow: ClinicalColors.lightShadow,
    shadowStrong: ClinicalColors.lightShadowStrong,
  );

  static final ClinicalPalette _darkPalette = ClinicalPalette(
    brightness: Brightness.dark,
    background: ClinicalColors.darkBackground,
    surface: ClinicalColors.darkSurface,
    surfaceElevated: ClinicalColors.darkSurfaceElevated,
    ink: ClinicalColors.darkInk,
    inkMuted: ClinicalColors.darkInkMuted,
    inkSubtle: ClinicalColors.darkInkSubtle,
    brandPrimary: ClinicalColors.darkBrandPrimary,
    brandPrimarySoft: ClinicalColors.darkBrandPrimarySoft,
    accentAmber: ClinicalColors.darkAccentAmber,
    accentAmberSoft: ClinicalColors.darkAccentAmberSoft,
    critical: ClinicalColors.darkCritical,
    criticalSoft: ClinicalColors.darkCriticalSoft,
    border: ClinicalColors.darkBorder,
    borderFocus: ClinicalColors.darkBorderFocus,
    shadow: ClinicalColors.darkShadow,
    shadowStrong: ClinicalColors.darkShadowStrong,
  );

  // ===== ACCESSEURS DE PALETTE =====
  static ClinicalPalette lightPalette() => _lightPalette;
  static ClinicalPalette darkPalette() => _darkPalette;

  // ===== THEME DATA =====
  static ThemeData light() => _buildTheme(_lightPalette);
  static ThemeData dark() => _buildTheme(_darkPalette);

  static ThemeData _buildTheme(ClinicalPalette p) {
    final inputStroke = p.isDark
        ? p.border : ClinicalColors.lightBorderStrong;

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.brandPrimary,
      onPrimary: p.surfaceElevated,
      primaryContainer: p.brandPrimarySoft,
      onPrimaryContainer: p.ink,
      secondary: p.accentAmber,
      onSecondary: p.surfaceElevated,
      secondaryContainer: p.accentAmberSoft,
      onSecondaryContainer: p.ink,
      tertiary: p.ink,
      onTertiary: p.background,
      error: p.critical,
      onError: p.surfaceElevated,
      errorContainer: p.criticalSoft,
      onErrorContainer: p.ink,
      surface: p.surface,
      onSurface: p.ink,
      surfaceDim: p.background,
      surfaceBright: p.surfaceElevated,
      surfaceContainerLowest: p.surfaceElevated,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceElevated,
      surfaceContainerHighest: p.brandPrimarySoft,
      onSurfaceVariant: p.inkMuted,
      outline: p.isDark ? p.border : ClinicalColors.lightBorderStrong,
      outlineVariant: p.border,
      shadow: p.shadow,
      inverseSurface: p.ink,
      onInverseSurface: p.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      shadowColor: p.shadow,
      dividerColor: p.border,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ClinicalTypography.headlineSmall.copyWith(
          color: p.ink,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: p.ink, size: 24),
      ),
      textTheme: TextTheme(
        displayLarge: ClinicalTypography.display.copyWith(color: p.ink),
        headlineLarge: ClinicalTypography.headlineLarge.copyWith(color: p.ink),
        headlineMedium: ClinicalTypography.headlineMedium.copyWith(color: p.ink),
        headlineSmall: ClinicalTypography.headlineSmall.copyWith(color: p.ink),
        titleLarge: ClinicalTypography.titleLarge.copyWith(color: p.ink),
        titleMedium: ClinicalTypography.titleMedium.copyWith(color: p.ink),
        bodyLarge: ClinicalTypography.bodyLarge.copyWith(color: p.ink),
        bodyMedium: ClinicalTypography.bodyMedium.copyWith(color: p.ink),
        bodySmall: ClinicalTypography.bodySmall.copyWith(color: p.ink),
        labelLarge: ClinicalTypography.labelLarge.copyWith(color: p.ink),
        labelMedium: ClinicalTypography.labelMedium.copyWith(color: p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.cardDefault),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
        hintStyle: TextStyle(color: p.inkSubtle, fontSize: 13),
        labelStyle: TextStyle(color: p.inkMuted, fontSize: 13),
        prefixIconColor: p.inkMuted,
        suffixIconColor: p.inkMuted,
        floatingLabelStyle: TextStyle(color: p.brandPrimary, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.input),
          borderSide: BorderSide(color: inputStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.input),
          borderSide: BorderSide(color: inputStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.input),
          borderSide: BorderSide(color: p.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.input),
          borderSide: BorderSide(color: p.critical, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.input),
          borderSide: BorderSide(color: p.critical, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.isDark
              ? ClinicalColors.darkActionFill : ClinicalColors.lightActionFill,
          foregroundColor: ClinicalColors.actionOnDarkFill,
          elevation: 0,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          shape: const StadiumBorder(),
          textStyle: ClinicalTypography.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.isDark
              ? ClinicalColors.darkActionFill : ClinicalColors.lightActionFill,
          foregroundColor: ClinicalColors.actionOnDarkFill,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.border, width: 1),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 11),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          shape: const StadiumBorder(),
          textStyle: ClinicalTypography.labelMedium,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.ink,
          shape: const CircleBorder(),
        ),
      ),
      iconTheme: IconThemeData(color: p.ink),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceElevated,
        selectedColor: p.brandPrimarySoft,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.chip),
        ),
        labelStyle: TextStyle(color: p.ink, fontSize: 13),
        checkmarkColor: p.brandPrimary,
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.button),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.brandPrimary,
        selectionColor: p.brandPrimarySoft,
        selectionHandleColor: p.brandPrimary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ClinicalRadius.modal),
            topRight: Radius.circular(ClinicalRadius.modal),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadius.modal),
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: p.brandPrimary,
        scaffoldBackgroundColor: p.background,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: ClinicalTypography.headlineSmall.copyWith(
            color: p.ink,
          ),
        ),
      ),
    );
  }
}

/// Palette sémantique résolue selon le mode.
class ClinicalPalette {
  const ClinicalPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.brandPrimary,
    required this.brandPrimarySoft,
    required this.accentAmber,
    required this.accentAmberSoft,
    required this.critical,
    required this.criticalSoft,
    required this.border,
    required this.borderFocus,
    required this.shadow,
    required this.shadowStrong,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color brandPrimary;
  final Color brandPrimarySoft;
  final Color accentAmber;
  final Color accentAmberSoft;
  final Color critical;
  final Color criticalSoft;
  final Color border;
  final Color borderFocus;
  final Color shadow;
  final Color shadowStrong;

  bool get isDark => brightness == Brightness.dark;

  /// Résout une paire clair/sombre selon le mode courant.
  Color resolve(Color light, Color dark) => isDark ? dark : light;
}