import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

Future<void> openAccessScreen(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
  await tester.tap(find.byKey(const Key('onboarding-skip')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('welcome-access')), findsOneWidget);
}

void main() {
  testWidgets('P4.6 connected Android entry never exposes demo workspace',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = DevAuthApi(Uri.parse('https://medisuivi-staging.invalid'));
    addTearDown(api.close);

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: MediSuiviWelcomeGate(
        developmentAuthApi: api,
        isWebDemo: true,
        child: const Text('FORBIDDEN DEMO WORKSPACE'),
      ),
    ));
    await openAccessScreen(tester);

    expect(find.byKey(const Key('welcome-demo')), findsNothing);
    expect(find.text('Explorer la démonstration'), findsNothing);
    expect(find.text('FORBIDDEN DEMO WORKSPACE'), findsNothing);
    expect(find.byKey(const Key('welcome-login')), findsOneWidget);
    expect(find.byKey(const Key('welcome-create')), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-signin')), findsOneWidget);
    expect(find.text('FORBIDDEN DEMO WORKSPACE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('P4.6 offline demo-only build keeps explicit demo entry',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: const MediSuiviWelcomeGate(
        isWebDemo: true,
        child: Text('SYNTHETIC DEMO WORKSPACE'),
      ),
    ));
    await openAccessScreen(tester);

    expect(find.byKey(const Key('welcome-demo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome-demo')));
    await tester.pumpAndSettle();
    expect(find.text('SYNTHETIC DEMO WORKSPACE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
