/// Design Tokens — Nocturne Clinique
/// Source unique de vérité pour couleurs, typographie, espacements, rayons, ombres, animations.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de couleurs sémantiques — Nocturne Clinique
abstract final class ClinicalColors {
  // ===== MODE CLAIR — "Sauge & Lin" (surfaces mates à hiérarchie lisible) =====
  static const Color lightBackground = Color(0xFFE9E8E0);
  static const Color lightSurface = Color(0xFFF3F2EA);
  static const Color lightSurfaceElevated = Color(0xFFFAF8F2);
  static const Color lightInk = Color(0xFF1D3027);
  static const Color lightInkMuted = Color(0xFF465B50);
  static const Color lightInkSubtle = Color(0xFF52665A);
  static const Color lightBrandPrimary = Color(0xFF285642);
  // Actions : olive profond, moins saturé que la couleur d'accent.
  // Fond et texte distincts pour conserver une lisibilité élevée.
  static const Color lightActionFill = Color(0xFF285642);
  static const Color darkActionFill = Color(0xFF3A5F4F);
  static const Color actionOnDarkFill = Color(0xFFF7F8F5);
  static const Color lightBrandPrimarySoft = Color(0xFFDAE9DE);
  static const Color lightAccentAmber = Color(0xFF79500B);
  static const Color lightAccentAmberSoft = Color(0xFFF2E5CA);
  static const Color lightCritical = Color(0xFF9C3836);
  static const Color lightCriticalSoft = Color(0xFFF0DFDA);
  static const Color lightBorder = Color(0xFFB0BDB0);
  static const Color lightBorderFocus = Color(0xFF285642);
  // Bordure des champs : >= 3:1 sur la surface de saisie.
  static const Color lightBorderStrong = Color(0xFF7C907E);
  static const Color lightShadow = Color(0x141C1A18); // 8% opacity
  static const Color lightShadowStrong = Color(0x291C1A18); // 16% opacity

  // ===== MODE SOMBRE — "Nuit Opératoire" =====
  static const Color darkBackground = Color(0xFF0D0F0E);
  static const Color darkSurface = Color(0xFF161917);
  static const Color darkSurfaceElevated = Color(0xFF1E221F);
  static const Color darkInk = Color(0xFFF0EDE8);
  static const Color darkInkMuted = Color(0xFFA8A096);
  static const Color darkInkSubtle = Color(0xFF6D675E);
  static const Color darkBrandPrimary = Color(0xFF5EC49D);
  static const Color darkBrandPrimarySoft = Color(0xFF1A3D2E);
  static const Color darkAccentAmber = Color(0xFFE8C56D);
  static const Color darkAccentAmberSoft = Color(0xFF3D341A);
  static const Color darkCritical = Color(0xFFE87A6A);
  static const Color darkCriticalSoft = Color(0xFF3D1E1E);
  static const Color darkBorder = Color(0xFF2A2E2B);
  static const Color darkBorderFocus = Color(0xFF5EC49D);
  static const Color darkShadow = Color(0x52000000); // 32% opacity
  static const Color darkShadowStrong = Color(0x7A000000); // 48% opacity

  // ===== SÉMANTIQUES (aliases pour usage dans les composants) =====
  // Ces valeurs sont résolues au runtime selon le thème actif via ClinicalThemeData
}

/// Tokens de typographie
abstract final class ClinicalTypography {
  // Font families
  static const String fontFamilyDisplay = 'DM Sans';
  static const String fontFamilyUI = 'DM Sans';
  static const String fontFamilyMono = 'DM Sans';

  // Fallback stacks (si polices non chargées)
  static const String fontFamilyDisplayFallback = 'DM Sans, sans-serif';
  static const String fontFamilyUIFallback = 'DM Sans, sans-serif';
  static const String fontFamilyMonoFallback = 'DM Sans, sans-serif';

  // Échelle mobile (base)
  static const TextStyle display = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.6,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.15,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle monoLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.15,
  );
}

/// Échelle commune d'écriture pour tous les modules MediSuivi.
abstract final class ClinicalTypeScale {
  static const double hero = 32;
  static const double page = 23;
  static const double section = 17;
  static const double rowTitle = 16;
  static const double body = 14;
  static const double secondary = 13.5;
  static const double caption = 12;
  static const double nav = 11;
}

/// Tokens d'espacement (base 4px)
abstract final class ClinicalSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // Espacements sémantiques
  static const double screenPaddingHorizontal = lg; // 16
  static const double screenPaddingVertical = xl; // 20
  static const double cardPaddingCompact = md; // 12
  static const double cardPaddingComfortable = 14; // 14, plus compact
  static const double cardPaddingSpacious = 18; // 18
  static const double sectionGap = xl; // 20
  static const double groupGap = lg; // 16
  static const double fieldGap = md; // 12
}

/// Tokens de rayons
abstract final class ClinicalRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 9999;

  // Rayons sémantiques
  static const double cardDefault = xl; // 20
  static const double cardElevated = xxl; // 24
  static const double button = xxl; // 24, coins généreusement arrondis
  static const double chip = lg; // 16
  static const double avatar = full;
  static const double input = xl; // 20
  static const double modal = xxl; // 24
  static const double navItem = xxl; // 24
}

/// Tokens d'ombres
abstract final class ClinicalShadow {
  static const List<BoxShadow> level0 = [];
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x141C1A18),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x141C1A18),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A1C1A18),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1F1C1A18),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x141C1A18),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: Color(0x331C1A18),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x1F1C1A18),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  // Ombres mode sombre (plus marquées)
  static const List<BoxShadow> level1Dark = [
    BoxShadow(
      color: Color(0x52000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  static const List<BoxShadow> level2Dark = [
    BoxShadow(
      color: Color(0x52000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  static const List<BoxShadow> level3Dark = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> level4Dark = [
    BoxShadow(
      color: Color(0x7A000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];
}

/// Résolveur de polices Google Fonts — utilisé pour le rendu runtime
final GoogleFonts googleFonts = GoogleFonts();

// Tokens d'animations
abstract final class ClinicalMotion {
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration brisk = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration gentle = Duration(milliseconds: 420);

  static const Curve easeOut = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Curve easeInOut = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve spring = Curves.easeOutCubic; // Approximation Flutter

  static const Duration staggerBase = Duration(milliseconds: 40);
  static const Duration staggerMax = Duration(milliseconds: 400);
}

// Google Fonts — rendu runtime (fractionné au démarrage)
// Ces styles ne sont PAS const car GoogleFonts résout les polices à l'exécution.
// Elles sont disponible via ClinicalTypographyGoogleFonts.xxx si besoin.
class ClinicalTypographyGoogleFonts {
  // Display — Fraunces
  static TextStyle display = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -1.2,
  );
  static TextStyle headlineLarge = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.6,
  );
  static TextStyle headlineMedium = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.3,
  );
  static TextStyle headlineSmall = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -0.15,
  );

  // UI — DM Sans
  static TextStyle titleLarge = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0,
  );
  static TextStyle titleMedium = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );
  static TextStyle bodyLarge = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );
  static TextStyle bodyMedium = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
  );
  static TextStyle bodySmall = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  // Mono — JetBrains Mono
  static TextStyle monoLarge = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
  );
  static TextStyle monoMedium = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
  );
  static TextStyle monoSmall = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
  );

  // Étiquettes — DM Sans
  static TextStyle labelLarge = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );
  static TextStyle labelMedium = TextStyle(fontFamily: ClinicalTypography.fontFamilyUI, 
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.15,
  );
}

/// Densités de carte
enum ClinicalCardDensity { compact, comfortable, spacious }

/// Variantes de carte
enum ClinicalCardVariant { default_, elevated, outlined, filled }

/// Breakpoints responsive
abstract final class ClinicalBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}

/// Tailles cibles tactiles
abstract final class ClinicalTouchTarget {
  static const double minSize = 48;
  static const double iconSize = 24;
  static const double navIconSize = 24;
  static const double avatarSmall = 32;
  static const double avatarDefault = 40;
  static const double avatarComfortable = 48;
  static const double avatarHero = 64;
  static const double avatarDetail = 80;
}