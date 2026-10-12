import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/features/exams/exam_detail_screen.dart';
import 'package:medisuivi/features/exams/exam_editor_screen.dart';
import 'package:medisuivi/features/exams/exams_screen.dart';

void main() {
  late DemoStore store;
  setUp(() => store = DemoStore());
  tearDown(() => store.dispose());

  Future<void> showScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(DemoScope(store: store,
      child: MaterialApp(theme: MediTheme.light(), home: screen)));
    await tester.pumpAndSettle();
  }

  testWidgets('Lire un compte rendu existant', (tester) async {
    await showScreen(tester, const ExamDetailScreen(examId: 'EXM-001'));
    expect(find.text('Compte rendu de l’examen'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data,
      'Compte rendu enregistré.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sauvegarder un résultat puis le consulter', (tester) async {
    await showScreen(tester, const ExamDetailScreen(examId: 'EXM-002'));
    await tester.ensureVisible(find.text('Saisir le résultat'));
    await tester.tap(find.text('Saisir le résultat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first,
      'Compte rendu de contrôle enregistré');
    await tester.ensureVisible(find.text('Enregistrer le résultat'));
    await tester.tap(find.text('Enregistrer le résultat'));
    await tester.pumpAndSettle();
    expect(find.text('Détail du bilan'), findsOneWidget);
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data,
      contains('Compte rendu de contrôle'));
    expect(store.examById('EXM-002')?.resultRecordedAt, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prescription créée : sa fiche est accessible aussitôt',
      (tester) async {
    final before = store.exams.length;
    await showScreen(tester, const ExamEditorScreen(
      patientId: 'PAT-00240'));
    await tester.enterText(find.byType(TextFormField).first,
      'Bilan de contrôle');
    await tester.ensureVisible(find.text('Ajouter la prescription'));
    await tester.tap(find.text('Ajouter la prescription'));
    await tester.pumpAndSettle();
    expect(store.exams.length, before + 1);
    expect(find.text('Détail du bilan'), findsOneWidget);
    expect(find.text('Bilan de contrôle'), findsOneWidget);
    expect(find.text('Résultat en attente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Les bilans ouvrent le rapport et non le dossier patient',
      (tester) async {
    await showScreen(tester, const Scaffold(body: ExamsScreen()));
    await tester.ensureVisible(find.text('Numération formule sanguine'));
    await tester.tap(find.text('Numération formule sanguine'));
    await tester.pumpAndSettle();
    expect(find.text('Détail du bilan'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Un résultat finalisé ne peut pas être écrasé silencieusement', () {
    store.recordExamResult(examId: 'EXM-002', result: 'Compte rendu');
    expect(() => store.recordExamResult(
      examId: 'EXM-002', result: 'Modification'),
      throwsStateError);
  });
}
