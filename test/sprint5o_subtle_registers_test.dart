import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/widgets/medical_ui.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        '5O: chaque dossier possède son contour discret à ${width.toInt()}px/${mode.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MediSuiviApp(themeMode: mode));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('dock-patients')));
          await tester.pumpAndSettle();
          final register = find.byKey(const Key('patients-compact-register'));
          expect(register, findsOneWidget);
          final rows = tester.widget<ClinicalGroupedList>(register);
          expect(rows.children.length, 5);

          final first = find.descendant(
            of: register,
            matching: find.byKey(const Key('clinical-list-outline-0')),
          );
          expect(first, findsOneWidget);
          final tile = tester.widget<Material>(first);
          final shape = tile.shape as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(15));
          expect(shape.side.width, closeTo(.85, .01));
          expect(shape.side.color.a, lessThan(1));
          expect(tile.elevation, 0);

          await tester.tap(find.descendant(
            of: first,
            matching: find.byType(InkWell)).first);
          await tester.pumpAndSettle();
          expect(find.text('Aminata Diallo'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
