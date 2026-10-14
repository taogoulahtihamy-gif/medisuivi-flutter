import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_account_access_screen.dart';

void main() {
  for (final isRegister in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        'P4.9 original ${isRegister ? "inscription" : "connexion"} '
        '${dark ? "sombre" : "clair"} sans photo à 320px',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = DevAuthApi(
            Uri.parse('https://medisuivi-ci.invalid'));
          addTearDown(api.close);

          await tester.pumpWidget(MaterialApp(
            theme: MediTheme.light(),
            darkTheme: MediTheme.dark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: OriginalAccountAccessScreen(
              api: api,
              isRegister: isRegister,
              onBack: () {},
              onToggle: () {},
              onAuthenticated: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(Image), findsNothing,
              reason: 'Authentification originale sans photo décorative.');
          expect(find.byKey(const Key('dev-auth-email')), findsOneWidget);
          expect(find.byKey(const Key('dev-auth-password')), findsOneWidget);
          expect(find.byKey(const Key('dev-auth-submit')), findsOneWidget);
          expect(find.byKey(const Key('dev-auth-warning')), findsOneWidget);
          expect(find.byKey(const Key('dev-register-first-name')),
              isRegister ? findsOneWidget : findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
