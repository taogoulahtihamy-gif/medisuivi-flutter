import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Palette Nocturne Clinique — accès statique (valeurs claires,
/// pour les contextes `const`) et résolution par contexte.
///
/// Usage constant : `Palette.muted` (toujours clair).
/// Usage recommandé : `Palette.of(context).muted` (s'adapte au mode).
abstract final class Palette {
  Palette._();

  // ===== ACCÈS PAR CONTEXTE (recommandé) =====
  static PaletteData of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? PaletteData.dark() : PaletteData.light();
  }

  // ===== CONSTANTES CLAIRES (pour const, compatibilité) =====
  static const Color canvas = ClinicalColors.lightBackground;
  static const Color white = ClinicalColors.lightSurfaceElevated;
  static const Color ink = ClinicalColors.lightInk;
  static const Color muted = ClinicalColors.lightInkMuted;
  static const Color border = ClinicalColors.lightBorder;
  static const Color forest = ClinicalColors.lightBrandPrimary;
  static const Color teal = ClinicalColors.lightBrandPrimary;
  static const Color tealDark = ClinicalColors.lightInk;
  static const Color tealSoft = ClinicalColors.lightBrandPrimarySoft;
  static const Color navy = ClinicalColors.lightInk;
  static const Color charcoal = ClinicalColors.lightInk;
  static const Color charcoalSoft = ClinicalColors.lightInkMuted;
  static const Color canvasEditorial = ClinicalColors.lightBackground;
  static const Color aqua = ClinicalColors.lightBrandPrimarySoft;
  static const Color blueSoft = ClinicalColors.lightAccentAmberSoft;
  static const Color lavenderSoft = ClinicalColors.lightBrandPrimarySoft;
  static const Color amber = ClinicalColors.lightAccentAmber;
  static const Color amberSoft = ClinicalColors.lightAccentAmberSoft;
  static const Color danger = ClinicalColors.lightCritical;
  static const Color surface = ClinicalColors.lightSurface;
  static const Color raisedSurface = ClinicalColors.lightSurfaceElevated;
  static const Color night = ClinicalColors.lightInk;
  static const Color laser = ClinicalColors.lightBrandPrimary;
  static const Color laserMuted = ClinicalColors.lightInkMuted;
  static const Color laserBorder = ClinicalColors.lightBorder;
  static const Color laserVeil = ClinicalColors.lightBrandPrimarySoft;
}

/// Données de palette pour un mode donné (clair ou sombre).
/// Conserve les noms historiques pour compatibilité des écrans.
class PaletteData {
  PaletteData._(this._isDark);

  final bool _isDark;

  factory PaletteData.light() => PaletteData._(false);
  factory PaletteData.dark() => PaletteData._(true);

  bool get isDark => _isDark;

  Color get canvas => _isDark ? ClinicalColors.darkBackground : ClinicalColors.lightBackground;
  Color get white => _isDark ? ClinicalColors.darkSurfaceElevated : ClinicalColors.lightSurfaceElevated;
  Color get ink => _isDark ? ClinicalColors.darkInk : ClinicalColors.lightInk;
  Color get muted => _isDark ? ClinicalColors.darkInkMuted : ClinicalColors.lightInkMuted;
  Color get border => _isDark ? ClinicalColors.darkBorder : ClinicalColors.lightBorder;
  Color get forest => _isDark ? ClinicalColors.darkBrandPrimary : ClinicalColors.lightBrandPrimary;
  Color get teal => forest;
  Color get tealDark => ink;
  Color get tealSoft => _isDark ? ClinicalColors.darkBrandPrimarySoft : ClinicalColors.lightBrandPrimarySoft;
  Color get navy => ink;
  Color get charcoal => ink;
  Color get charcoalSoft => muted;
  Color get canvasEditorial => canvas;
  Color get aqua => tealSoft;
  Color get blueSoft => _isDark ? ClinicalColors.darkAccentAmberSoft : ClinicalColors.lightAccentAmberSoft;
  Color get lavenderSoft => tealSoft;
  Color get amber => _isDark ? ClinicalColors.darkAccentAmber : ClinicalColors.lightAccentAmber;
  Color get amberSoft => _isDark ? ClinicalColors.darkAccentAmberSoft : ClinicalColors.lightAccentAmberSoft;
  Color get danger => _isDark ? ClinicalColors.darkCritical : ClinicalColors.lightCritical;
  Color get surface => _isDark ? ClinicalColors.darkSurface : ClinicalColors.lightSurface;
  Color get raisedSurface => _isDark ? ClinicalColors.darkSurfaceElevated : ClinicalColors.lightSurfaceElevated;
  Color get night => ink;
  Color get laser => forest;
  Color get laserMuted => muted;
  Color get laserBorder => border;
  Color get laserVeil => tealSoft;
}

/// Thème Nocturne Clinique — modes clair et sombre.
/// Utilise la palette résolue pour garantir la cohérence
/// entre les composants historiques et les nouveaux.
abstract final class MediTheme {
  static ThemeData light() => _build(PaletteData.light());
  static ThemeData dark() => _build(PaletteData.dark());

  static ThemeData _build(PaletteData p) {
    final scheme = ColorScheme(
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primary: p.forest,
      onPrimary: p.white,
      primaryContainer: p.tealSoft,
      onPrimaryContainer: p.ink,
      secondary: p.navy,
      onSecondary: p.white,
      secondaryContainer: p.tealSoft,
      onSecondaryContainer: p.ink,
      tertiary: p.forest,
      onTertiary: p.white,
      error: p.danger,
      onError: p.white,
      errorContainer: p.amberSoft,
      onErrorContainer: p.ink,
      surface: p.surface,
      onSurface: p.ink,
      surfaceDim: p.canvas,
      surfaceBright: p.raisedSurface,
      surfaceContainerLowest: p.raisedSurface,
      surfaceContainerLow: p.canvas,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.raisedSurface,
      surfaceContainerHighest: p.tealSoft,
      onSurfaceVariant: p.muted,
      outline: p.isDark ? p.border : ClinicalColors.lightBorderStrong,
      outlineVariant: p.border,
      shadow: p.ink,
      inverseSurface: p.ink,
      onInverseSurface: p.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
    );
    final inputStroke = p.isDark
        ? p.border : ClinicalColors.lightBorderStrong;

    final text = const TextTheme(
      headlineLarge: TextStyle(fontSize: 27, height: 1.13,
        fontWeight: FontWeight.w700, letterSpacing: -0.8),
      headlineMedium: TextStyle(fontSize: 23, height: 1.19,
        fontWeight: FontWeight.w700, letterSpacing: -0.6),
      titleLarge: TextStyle(fontSize: 19, height: 1.28,
        fontWeight: FontWeight.w700, letterSpacing: -0.35),
      titleMedium: TextStyle(fontSize: 16, height: 1.3,
        fontWeight: FontWeight.w600, letterSpacing: -0.2),
      bodyLarge: TextStyle(fontSize: 15, height: 1.44,
        fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 13.5, height: 1.43),
      bodySmall: TextStyle(fontSize: 13, height: 1.42),
      labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    ).apply(bodyColor: p.ink, displayColor: p.ink);

    return base.copyWith(
      scaffoldBackgroundColor: p.canvas,
      colorScheme: scheme,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: p.ink,
          fontSize: 19, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.raisedSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: p.muted, fontSize: 13.5),
        labelStyle: TextStyle(color: p.muted, fontSize: 13.5),
        floatingLabelStyle: TextStyle(color: p.forest, fontSize: 13.5),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.forest, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.danger, width: 1.7),
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
          textStyle: const TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600),
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
          side: BorderSide(color: p.border),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 11),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.ink,
          shape: const CircleBorder(),
        ),
      ),
      iconTheme: IconThemeData(color: p.ink),
      listTileTheme: p.isDark ? null : ListTileThemeData(
        textColor: p.ink,
        iconColor: p.forest,
        titleTextStyle: TextStyle(
          color: p.ink, fontSize: 14.5, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(
          color: p.muted, fontSize: 12.8, height: 1.35),
      ),
      switchTheme: p.isDark ? null : SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? p.raisedSurface : p.muted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? p.forest : p.tealSoft),
        trackOutlineColor: WidgetStateProperty.all(inputStroke),
      ),
      checkboxTheme: p.isDark ? null : CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? p.forest : Colors.transparent),
        checkColor: WidgetStateProperty.all(p.white),
        side: BorderSide(color: inputStroke, width: 1.4),
      ),
      progressIndicatorTheme: p.isDark ? null : ProgressIndicatorThemeData(
        color: p.forest, linearTrackColor: p.tealSoft),
      floatingActionButtonTheme: p.isDark ? null : FloatingActionButtonThemeData(
        backgroundColor: p.forest, foregroundColor: p.white),
      popupMenuTheme: p.isDark ? null : PopupMenuThemeData(
        color: p.raisedSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: p.ink, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: p.border))),
      dialogTheme: p.isDark ? null : DialogThemeData(
        backgroundColor: p.raisedSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: p.ink, fontWeight: FontWeight.w700, fontSize: 19),
        contentTextStyle: TextStyle(
          color: p.muted, fontSize: 14, height: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.border))),
      dividerColor: p.border,
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.tealSoft,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: p.ink,
          fontSize: 13, fontWeight: FontWeight.w600),
        checkmarkColor: p.forest,
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.navy,
        contentTextStyle: TextStyle(color: p.white),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.forest,
        selectionColor: p.tealSoft,
        selectionHandleColor: p.forest,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: p.forest),
    );
  }
}