import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_profile_editor.dart';

void main() {
  const original = DevPractitioner(
    id: 'practitioner-a', email: 'alpha@medisuvi-ci.org',
    firstName: 'Awa', lastName: 'Test');
  const session = DevSession(
    practitioner: original, accessToken: 'token-alpha');

  test('P3.2: update and private avatar request carry only current token',
      () async {
    final calls = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((req) async {
        calls.add(req);
        if (req.url.path == '/api/v1/me' && req.method == 'PUT') {
          return http.Response(jsonEncode({
            'id':'practitioner-a', 'email':'alpha@medisuvi-ci.org',
            'first_name':'Awa', 'last_name':'Diop',
            'phone':'+221701234567', 'specialty':'Médecine',
            'has_avatar':false}), 200);
        }
        if (req.url.path == '/api/v1/me/avatar' && req.method == 'PUT') {
          return http.Response(jsonEncode({
            'id':'practitioner-a', 'email':'alpha@medisuvi-ci.org',
            'first_name':'Awa', 'last_name':'Diop',
            'phone':'+221701234567', 'specialty':'Médecine',
            'has_avatar':true}), 200);
        }
        if (req.url.path == '/api/v1/me/avatar' && req.method == 'GET') {
          return http.Response.bytes(Uint8List.fromList([82, 73, 70, 70]), 200,
            headers:{'content-type':'image/webp'});
        }
        if (req.url.path == '/api/v1/me/avatar' && req.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      }));

    final profile = await api.updateProfile(session, firstName:'Awa',
      lastName:'Diop', phone:'+221701234567', specialty:'Médecine');
    expect(profile.displayName, 'Awa Diop');
    expect(profile.phone, '+221701234567');
    expect(profile.specialty, 'Médecine');
    final changed = await api.uploadAvatar(session,
      Uint8List.fromList([0xFF,0xD8,0xFF,0xD9]), mimeType:'image/jpeg');
    expect(changed.hasAvatar, isTrue);
    expect((await api.loadAvatar(session))!.length, 4);
    await api.removeAvatar(session);
    expect(calls.length, 4);
    expect(calls.every((x) =>
      x.headers['authorization'] == 'Bearer token-alpha'), isTrue);
    expect(calls[1].headers['content-type'], 'image/jpeg');
    expect(calls[1].bodyBytes, [0xFF,0xD8,0xFF,0xD9]);
    api.close();
  });

  testWidgets('P3.2: profile edits are visible and returned to workspace',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DevPractitioner? saved;
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((req) async {
        if (req.url.path == '/api/v1/me' && req.method == 'PUT') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({
            'id':'practitioner-a', 'email':'alpha@medisuvi-ci.org',
            ...body, 'has_avatar':false}), 200);
        }
        return http.Response('{}', 404);
      }));
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: Scaffold(body: Builder(builder: (context) =>
        FilledButton(key: const Key('open-edit'), onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => DevProfileEditor(
              api: api, session: session, initial: original, avatar: null,
              onChanged: (updated, _) => saved = updated,
            ))),
          child: const Text('Modifier le profil')))),
    ));
    await tester.tap(find.byKey(const Key('open-edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dev-profile-photo')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('dev-profile-first')), 'Awa');
    await tester.enterText(find.byKey(const Key('dev-profile-last')), 'Diop');
    await tester.enterText(
      find.byKey(const Key('dev-profile-phone')), '+221701234567');
    await tester.enterText(
      find.byKey(const Key('dev-profile-specialty')), 'Médecine générale');
    await tester.ensureVisible(find.byKey(const Key('dev-profile-save')));
    await tester.tap(find.byKey(const Key('dev-profile-save')));
    await tester.pumpAndSettle();
    expect(saved?.displayName, 'Awa Diop');
    expect(saved?.specialty, 'Médecine générale');
    expect(find.byKey(const Key('open-edit')), findsOneWidget);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
