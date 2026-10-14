import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_auth_screens.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(390, 850)]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final isRegister in [false, true]) {
        testWidgets('P4.8 compact clinical authentication layout ${size.width}/'
            '${mode.name}/${isRegister ? "register" : "login"}',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'));
          addTearDown(api.close);
          await tester.pumpWidget(MaterialApp(
            theme: MediTheme.light(),
            darkTheme: MediTheme.dark(),
            themeMode: mode,
            home: DevAuthScreen(
              api: api, isRegister: isRegister,
              onAuthenticated: (_) {}, onBack: () {}, onToggle: () {},
            ),
          ));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('dev-auth-warning')), findsOneWidget);
          expect(find.byKey(const Key('dev-auth-surface')), findsOneWidget);
          expect(find.byKey(const Key('dev-auth-brand-icon')), findsOneWidget);
          expect(find.byType(Image), findsNothing,
            reason: 'Les formulaires professionnels sont sans photo.');
          expect(find.byKey(const Key('dev-auth-email')), findsOneWidget);
          expect(find.byKey(const Key('dev-auth-password')), findsOneWidget);
          if (isRegister) {
            expect(find.byKey(const Key('dev-register-first-name')), findsOneWidget);
            expect(find.byKey(const Key('dev-register-last-name')), findsOneWidget);
          }
          await tester.ensureVisible(find.byKey(const Key('dev-auth-submit')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
