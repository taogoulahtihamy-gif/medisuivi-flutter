import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_account_access_screen.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932)
  ]) {
    for (final dark in [false, true]) {
      for (final register in [false, true]) {
        testWidgets(
            'P5.3 $size dark=$dark register=$register keyboard and text scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = DevAuthApi(Uri.parse('https://synthetic.invalid'));
          addTearDown(api.close);
          Future<void> render({double keyboard = 0, double scale = 1}) async {
            await tester.pumpWidget(MaterialApp(
              theme: dark ? MediTheme.dark() : MediTheme.light(),
              home: MediaQuery(
                  data: MediaQueryData(
                      size: size,
                      viewInsets: EdgeInsets.only(bottom: keyboard),
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true),
                  child: OriginalAccountAccessScreen(
                      api: api,
                      isRegister: register,
                      onBack: () {},
                      onToggle: () {},
                      onAuthenticated: (_) {})),
            ));
            await tester.pumpAndSettle();
          }

          await render();
          expect(find.byType(Card), findsNothing);
          await tester
              .ensureVisible(find.byTooltip('Afficher le mot de passe'));
          await tester.tap(find.byTooltip('Afficher le mot de passe'));
          await tester.pump();
          expect(
              tester.widget<TextFormField>(
                  find.byKey(const Key('dev-auth-password'))),
              isNotNull);
          expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
          await tester.tap(find.byTooltip('Masquer le mot de passe'));
          await tester.ensureVisible(find.byKey(const Key('dev-auth-submit')));
          await tester.tap(find.byKey(const Key('dev-auth-submit')));
          await tester.pumpAndSettle();
          expect(find.text('Adresse e-mail invalide'), findsOneWidget);
          await render(keyboard: 280, scale: 1.8);
          await tester.ensureVisible(find.byKey(const Key('dev-auth-submit')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('dev-auth-submit')).hitTestable(),
              findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
      'P5.3 loading prevents double submission and exposes server error',
      (tester) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final api = DevAuthApi(Uri.parse('https://synthetic.invalid'),
        client: MockClient((_) {
      requests++;
      return response.future;
    }));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
        theme: MediTheme.light(),
        home: OriginalAccountAccessScreen(
            api: api,
            isRegister: false,
            onBack: () {},
            onToggle: () {},
            onAuthenticated: (_) {})));
    await tester.enterText(
        find.byKey(const Key('dev-auth-email')), 'demo-a@example.com');
    await tester.enterText(
        find.byKey(const Key('dev-auth-password')), 'Synthetic-password');
    final submit = find.byKey(const Key('dev-auth-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    expect(requests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(http.Response('{}', 401));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dev-auth-error')), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });
}
