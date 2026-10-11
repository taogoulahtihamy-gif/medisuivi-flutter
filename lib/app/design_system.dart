import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const forest = Color(0xFF075E46);
  static const mint = Color(0xFFE8FFF2);
  static const background = Color(0xFFF8FCF9);
  static const ink = Color(0xFF183A2E);
  static const muted = Color(0xFF627A6E);
  static const border = Color(0xFFDDEEE4);
  static const deepForest = Color(0xFF064B39);
}

abstract final class AppSpacing {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
  static const page = EdgeInsets.fromLTRB(20, 24, 20, 32);
}

abstract final class AppRadius {
  static const field = 16.0, card = 22.0, hero = 26.0;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x0C075E46), blurRadius: 24, offset: Offset(0, 8))
  ];
}

abstract final class AppTypography {
  // No downloaded fonts: Flutter retains the platform's native font family.
  static TextTheme apply(TextTheme base) => base
      .copyWith(
        headlineLarge: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9),
        headlineSmall: const TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(fontSize: 15, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
        bodySmall: const TextStyle(fontSize: 12, height: 1.4),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      )
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
}

abstract final class AppMotion {
  static const micro = Duration(milliseconds: 160);
  static const transition = Duration(milliseconds: 290);
  static const entrance = Duration(milliseconds: 400);
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ||
              MediaQuery.accessibleNavigationOf(context)
          ? Duration.zero
          : value;
}

abstract final class AppIcons {
  static IconData adaptive(
          BuildContext context, IconData material, IconData cupertino) =>
      Theme.of(context).platform == TargetPlatform.iOS ? cupertino : material;
  static IconData settings(BuildContext context) =>
      adaptive(context, Icons.tune_rounded, CupertinoIcons.slider_horizontal_3);
}

class MedicalPageTransitions extends PageTransitionsBuilder {
  const MedicalPageTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (AppMotion.duration(context, AppMotion.transition) == Duration.zero) {
      return child;
    }
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
        opacity: curved,
        child: SlideTransition(
            position: Tween(begin: const Offset(.035, 0), end: Offset.zero)
                .animate(curved),
            child: child));
  }
}

class MedicalCupertinoTransitions extends CupertinoPageTransitionsBuilder {
  const MedicalCupertinoTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (AppMotion.duration(context, AppMotion.transition) == Duration.zero) {
      return child;
    }
    return super
        .buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
