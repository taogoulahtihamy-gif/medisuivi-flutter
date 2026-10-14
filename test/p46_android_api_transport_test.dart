import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

void main() {
  test('P4.6 local Android tunnel allows loopback only over HTTP', () {
    final local = DevAuthApi(Uri.parse('http://127.0.0.1:8027'));
    final emulator = DevAuthApi(Uri.parse('http://10.0.2.2:8027'));
    local.close();
    emulator.close();

    for (final url in [
      'http://192.168.1.10:8027',
      'http://10.10.0.1:8027',
      'http://medisuivi-staging.invalid',
      'http://example.org',
      'ftp://127.0.0.1:8027',
      'https://user:password@medisuivi-staging.invalid',
      'https://medisuivi-staging.invalid/?token=bad',
    ]) {
      expect(
        () => DevAuthApi(Uri.parse(url)),
        throwsArgumentError,
        reason: 'Unapproved API origin accepted: $url',
      );
    }

    final remote = DevAuthApi(
      Uri.parse('https://medisuivi-staging.invalid'));
    remote.close();
  });
}
