import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';

void main() {
  testWidgets('Accueil : portrait WebP HD intégré, même cadrage et accès hors ligne',
      (tester) async {
    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final hero = find.byKey(const Key('home-hero-hd-photo'));
    expect(hero, findsOneWidget);

    final image = tester.widget<Image>(hero);
    expect(image.image, isA<AssetImage>());
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.centerRight);
    expect(image.filterQuality, FilterQuality.high);

    final bytes = await rootBundle.load('assets/images/home_hero_pro.webp');
    expect(bytes.lengthInBytes, greaterThan(30000));
    expect(ascii.decode(bytes.buffer.asUint8List(8, 4)), 'WEBP');
    expect(ascii.decode(bytes.buffer.asUint8List(12, 4)), 'VP8 ');
    final width = bytes.getUint16(26, Endian.little) & 0x3fff;
    final height = bytes.getUint16(28, Endian.little) & 0x3fff;
    expect(width, greaterThanOrEqualTo(1600));
    expect(width / height, closeTo(2.5, 0.05));
    expect(tester.takeException(), isNull);
  });
}
