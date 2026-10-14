import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Patients : filtres et recherche à ${width.toInt()}px (${mode.name})',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MediSuiviApp(themeMode: mode));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dock-patients')));
        await tester.pumpAndSettle();

        final search = find.byKey(const Key('patients-search'));
        expect(search, findsOneWidget);
        expect(find.byKey(const Key('patients-filter-all')), findsOneWidget);
        expect(find.byKey(const Key('patients-filter-followup')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.enterText(search, 'zzz-patient-introuvable');
        await tester.pumpAndSettle();
        expect(find.text('Aucun dossier trouvé'), findsOneWidget);
        expect(find.byKey(const Key('patients-search-clear')), findsOneWidget);

        await tester.tap(find.byKey(const Key('patients-search-clear')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('patients-search-clear')), findsNothing);
        expect(find.text('Aminata Diallo'), findsWidgets);

        await tester.tap(find.byKey(const Key('patients-filter-followup')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('patients-filter-followup')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
