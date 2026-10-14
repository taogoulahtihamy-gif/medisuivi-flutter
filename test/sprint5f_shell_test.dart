import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';

void main() {
  testWidgets('Dock givré : cinq destinations et élévation de l’onglet actif à 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clinical-bottom-dock')), findsOneWidget);
    for (final label in ['Accueil', 'Patients', 'Bilans', 'Suivi', 'Réglages']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.byKey(const Key('dock-create-patient')), findsNothing);
    expect(find.byKey(const Key('clinical-dock-glass')), findsOneWidget);
    final homeLift = tester.widget<AnimatedSlide>(
      find.byKey(const Key('dock-lift-accueil')));
    expect(homeLift.offset.dy, lessThan(0));

    await tester.tap(find.byKey(const Key('dock-patients')));
    await tester.pumpAndSettle();
    final selectedLift = tester.widget<AnimatedSlide>(
      find.byKey(const Key('dock-lift-patients')));
    final inactiveLift = tester.widget<AnimatedSlide>(
      find.byKey(const Key('dock-lift-accueil')));
    expect(selectedLift.offset.dy, lessThan(0));
    expect(inactiveLift.offset, Offset.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thème clair sombre auto fonctionne depuis Réglages',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    // Le nouveau profil centré ajoute une zone d'identité :
    // dégager les choix de thème du dock flottant avant interaction.
    await tester.drag(find.byKey(const Key('settings-page-list')),
        const Offset(0, -175));
    await tester.pumpAndSettle();
    expect(find.text('Apparence'), findsOneWidget);
    expect(find.byKey(const Key('theme-light')), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Apparence'))).brightness,
      Brightness.light);
    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Apparence'))).brightness,
      Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profil et notifications locales accessibles depuis accueil',
      (tester) async {
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('header-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('À surveiller'), findsOneWidget);
    expect(find.textContaining('Aucune notification serveur'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('header-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Apparence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dernières constantes avant informations médicales',
      (tester) async {
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aminata Diallo').first);
    await tester.pumpAndSettle();
    final vitals = find.text('Dernières constantes');
    final info = find.text('Informations médicales');
    expect(vitals, findsOneWidget);
    expect(info, findsOneWidget);
    expect(tester.getTopLeft(vitals).dy, lessThan(tester.getTopLeft(info).dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Sidebar desktop : surface givrée et paramètres accessibles',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clinical-sidebar-glass')), findsOneWidget);
    expect(find.byKey(const Key('dock-create-patient')), findsNothing);
    expect(tester.takeException(), isNull);
  });

}
