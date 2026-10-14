import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/design_tokens.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/widgets/clinical_components.dart';

void main() {
  test('Nocturne Clinique : actions arrondies et couleur apaisée', () {
    for (final theme in [MediTheme.light(), MediTheme.dark()]) {
      final style = theme.elevatedButtonTheme.style!;
      final expected = theme.brightness == Brightness.dark
          ? ClinicalColors.darkActionFill : ClinicalColors.lightActionFill;
      expect(style.backgroundColor!.resolve({}), expected);
      expect(style.foregroundColor!.resolve({}),
        ClinicalColors.actionOnDarkFill);
      expect(style.shape!.resolve({}), isA<StadiumBorder>());
      expect(theme.filledButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>());
      expect(theme.outlinedButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>());
    }
  });

  testWidgets('Action consultation : compacte et utilisable à 320 px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var count = 0;
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: Scaffold(
        body: Center(
          child: ElevatedButton.icon(
            key: const Key('consultation-action'),
            onPressed: () => count++,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Consultation'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('consultation-action'));
    expect(tester.getSize(button).width, lessThan(300));
    expect(tester.takeException(), isNull);
    await tester.tap(button);
    await tester.pump();
    expect(count, 1);
  });

  testWidgets('ClinicalButton : taille naturelle, action accessible',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: Scaffold(body: Center(
        child: ClinicalButton(
          label: 'Nouveau patient',
          icon: Icons.add_rounded,
          onPressed: () => tapped = true,
        ),
      )),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ClinicalButton)).width,
      lessThan(300));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(ClinicalButton));
    expect(tapped, isTrue);
  });
}
