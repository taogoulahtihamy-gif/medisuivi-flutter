import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/home/home_screen.dart';

void main() {
  Future<void> configureScreen(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Nocturne Clinique : mode sombre complet dans les onglets',
      (tester) async {
    await configureScreen(tester, 360);
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.dark);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Vos dossiers'), findsOneWidget);
    for (final label in ['Patients', 'Bilans', 'Suivi', 'Accueil']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('Mode clair : surfaces et texte restent lisibles',
      (tester) async {
    await configureScreen(tester, 360);
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.light);
    expect(Palette.of(tester.element(find.byType(HomeScreen))).canvas,
      Palette.canvas);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navigation tablette (600 px) sur rail rétracté',
      (tester) async {
    await configureScreen(tester, 600);
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    expect(find.text('Mes patients'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navigation desktop (1100 px) sur rail déployé',
      (tester) async {
    await configureScreen(tester, 1100);
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.text('Bilans'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
