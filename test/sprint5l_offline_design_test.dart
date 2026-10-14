import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('5L : les cinq portraits haute résolution sont embarqués hors ligne', () async {
    const files = ['splash', 'records', 'followup', 'privacy', 'access'];
    for (final file in files) {
      final bytes = await rootBundle.load('assets/images/onboarding/$file.webp');
      expect(bytes.lengthInBytes, greaterThan(40000), reason: file);
      expect(String.fromCharCodes(bytes.buffer.asUint8List(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.buffer.asUint8List(8, 4)), 'WEBP');
    }
  });

  testWidgets('5L : démarrage visible plus de 1,5 s et photo réellement locale',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediSuiviWelcomeGate(
        isWebDemo: true, child: const MediSuiviApp(themeMode: ThemeMode.dark))));
    expect(find.byKey(const Key('welcome-splash-title')), findsOneWidget);
    final photo = tester.widget<Image>(
      find.byKey(const Key('welcome-splash-photo')));
    expect(photo.image, isA<AssetImage>());
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const Key('welcome-splash-title')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-pages')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('5L : préférences visuelles actives et registres compacts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dock-patients')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('patients-compact-register')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dock-bilans')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exams-compact-register')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dock-réglages')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('settings-more')),
      130, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byKey(const Key('settings-page-list')),
        const Offset(0, -175));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-reduce-motion')), findsOneWidget);
    expect(find.byKey(const Key('settings-compact-lists')), findsOneWidget);
    final compact = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-compact-lists')));
    expect(compact.value, isTrue);
    await tester.tap(find.byKey(const Key('settings-compact-lists')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-compact-lists'))).value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
