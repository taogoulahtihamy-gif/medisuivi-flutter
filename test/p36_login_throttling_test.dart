import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

void main() {
  test('P3.6: a throttled login displays a neutral French retry message',
      () async {
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        return http.Response(
          '{"detail":"Trop de tentatives. Réessayez plus tard."}', 429,
          headers: {'Retry-After': '900'});
      }));
    await expectLater(
      api.signIn('synthetic@medisuvi-ci.org', 'incorrect-password'),
      throwsA(isA<DevApiException>().having(
        (error) => error.message, 'message', contains('Trop de tentatives'))),
    );
    api.close();
  });
}
