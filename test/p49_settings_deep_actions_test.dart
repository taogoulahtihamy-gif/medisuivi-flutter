import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';

void main() {
  testWidgets('P4.9: sync, privacy, about and extra preferences all work',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dock-réglages')));
    await tester.pumpAndSettle();

    Future<void> openMain(String key) async {
      final scroll = find.descendant(
        of: find.byKey(const Key('settings-page-list')),
        matching: find.byType(Scrollable),
      ).first;
      tester.state<ScrollableState>(scroll).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(Key(key)), 160, scrollable: scroll);
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    Future<void> back() async {
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // Synchronization page, its data shortcut and server-info dialog.
    await openMain('settings-synchronization');
    await tester.tap(find.byKey(const Key('settings-sync-local-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('data-view-patients')), findsOneWidget);
    await back();
    await tester.tap(find.byKey(const Key('settings-sync-server-info')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    await back();

    // Confidentiality nested data/synchronization pages.
    await openMain('settings-privacy');
    await tester.tap(find.byKey(const Key('settings-privacy-local-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('data-view-patients')), findsOneWidget);
    await back();
    await tester.tap(find.byKey(const Key('settings-privacy-connections')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-sync-server-info')),
        findsOneWidget);
    await back();
    await back();

    // About: photo credits dialog and open-source licenses navigation.
    await openMain('settings-about');
    await tester.tap(find.byKey(const Key('about-photo-credits')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsOneWidget);
    await tester.tap(find.text('Fermer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    await back();
    await back();

    // Additional settings: active switches, language and nested pages.
    await openMain('settings-more');
    for (final key in ['settings-reduce-motion', 'settings-compact-lists']) {
      final control = find.byKey(Key(key));
      expect(tester.widget<SwitchListTile>(control).onChanged, isNotNull,
          reason: '$key must be interactive in the original app.');
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const Key('more-language')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-language-fr')), findsOneWidget);
    await back();
    await back();
    expect(find.byKey(const Key('settings-page-list')), findsOneWidget);
  });
}
