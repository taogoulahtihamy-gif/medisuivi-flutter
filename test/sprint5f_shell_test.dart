import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';

void main() {
  testWidgets('Barre basse : six actions accessibles à 320px',
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
    expect(find.byKey(const Key('dock-create-patient')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('dock-create-patient')));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter le patient'), findsOneWidget);
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
}
