import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

void main() {
  for (final dark in [false, true]) {
    for (final size in [
      const Size(320, 640),
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932)
    ]) {
      testWidgets('P5.3 entry navigation $size dark=$dark reduce motion',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = DevAuthApi(Uri.parse('https://synthetic.invalid'));
        addTearDown(api.close);
        const capture = bool.fromEnvironment('P53_CAPTURE');
        if (capture) {
          await tester.runAsync(() async {
            final loader = FontLoader('DM Sans')
              ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'));
            await loader.load();
            final fallback = FontLoader('Ahem')
              ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'));
            await fallback.load();
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
          });
        }
        final boundary = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            theme: dark ? MediTheme.dark() : MediTheme.light(),
            home: MediaQuery(
                data: MediaQueryData(size: size, disableAnimations: true),
                child: RepaintBoundary(
                    key: boundary,
                    child: MediSuiviWelcomeGate(
                        isWebDemo: true,
                        developmentAuthApi: api,
                        child: const SizedBox())))));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('onboarding-skip')));
        await tester.pumpAndSettle();
        Future<void> snapshot(String name) async {
          if (!capture || size.width != 390) return;
          await tester.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('/tmp/p53-$name-${dark ? 'dark' : 'light'}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        expect(
            tester
                .getTopLeft(find.byKey(const Key('welcome-clinical-brand')))
                .dy,
            lessThan(80));
        expect(find.byKey(const Key('welcome-login')).hitTestable(),
            findsOneWidget);
        // Keep the welcome copy and primary actions visually connected:
        // a Spacer-driven layout used to produce very large blank gaps.
        const headline = 'Vos patients,\nvos suivis.';
        expect(find.text(headline), findsOneWidget);
        final brandBottom = tester
            .getBottomLeft(find.byKey(const Key('welcome-clinical-brand')))
            .dy;
        final titleTop = tester.getTopLeft(find.text(headline)).dy;
        final loginTop =
            tester.getTopLeft(find.byKey(const Key('welcome-login'))).dy;
        expect(titleTop - brandBottom, inInclusiveRange(40, 110));
        expect(loginTop - titleTop, lessThan(250));
        expect(loginTop, lessThan(size.height * .8));
        await snapshot('welcome');
        await tester.tap(find.byKey(const Key('welcome-login')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dev-auth-email')), findsOneWidget);
        await snapshot('login');
        await tester.ensureVisible(find.byKey(const Key('dev-auth-toggle')));
        await tester.tap(find.byKey(const Key('dev-auth-toggle')));
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('dev-register-first-name')), findsOneWidget);
        await snapshot('register');
        await tester.ensureVisible(find.byKey(const Key('dev-auth-toggle')));
        await tester.tap(find.byKey(const Key('dev-auth-toggle')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dev-register-first-name')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
