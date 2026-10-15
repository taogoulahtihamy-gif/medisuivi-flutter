import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/main.dart' as medisuivi;

/// Runs INSIDE a GitHub-hosted Android emulator, not on the CI Linux host.
///
/// Only public and unauthenticated requests are made. No patient data, test
/// accounts, passwords, invitation codes or bypass tokens are required.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedOrigin = 'https://medisuivi-api-staging.vercel.app';
  const origin = String.fromEnvironment('MEDISUIVI_DEV_API_BASE_URL');

  testWidgets('Android trusts Vercel HTTPS and Neon readiness responds',
      (tester) async {
    expect(origin, expectedOrigin,
        reason: 'Android APK must target the audited public HTTPS sandbox.');
    expect(DevAuthApi.devBaseUrl, expectedOrigin);

    final client = http.Client();
    try {
      final health = await client
          .get(Uri.parse('$origin/health'))
          .timeout(const Duration(seconds: 45));
      expect(health.statusCode, 200,
          reason: 'Android must reach public FastAPI without Vercel bypass.');
      expect(
        (jsonDecode(health.body) as Map<String, dynamic>)['status'],
        'ok',
      );

      final ready = await client
          .get(Uri.parse('$origin/ready'))
          .timeout(const Duration(seconds: 45));
      expect(ready.statusCode, 200,
          reason: 'Android must reach the Neon-backed ready endpoint.');
      expect(
        (jsonDecode(ready.body) as Map<String, dynamic>)['ready'],
        true,
      );

      // Verify that the API does NOT expose clinical data anonymously.
      for (final path in ['/api/v1/me', '/api/v1/patients']) {
        final response = await client
            .get(Uri.parse('$origin$path'))
            .timeout(const Duration(seconds: 45));
        expect([401, 403], contains(response.statusCode),
            reason: 'Unauthenticated clinical route $path must stay private.');
      }
    } finally {
      client.close();
    }
  });

  testWidgets('original MediSuivi boots on Android with remote API configured',
      (tester) async {
    expect(origin, expectedOrigin);
    medisuivi.main();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      find.byKey(const ValueKey('welcome-splash')),
      findsOneWidget,
      reason: 'Launch must use the original MediSuivi Flutter welcome gate.',
    );
    expect(tester.takeException(), isNull);
  });
}
