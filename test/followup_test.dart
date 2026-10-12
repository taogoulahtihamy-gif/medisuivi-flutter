import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/models/medical_models.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/features/followup/followup_editor_screen.dart';
import 'package:medisuivi/features/followup/followup_screen.dart';

void main() {
  group('Suivi médical V0.5', () {
    late DemoStore store;

    setUp(() => store = DemoStore());
    tearDown(() => store.dispose());

    test('classification : en retard, aujourd’hui, à venir et minuit', () {
      final now = DateTime(2026, 10, 12, 10, 30);
      FollowUpPlan plan(DateTime due) => FollowUpPlan(
        id: 'FUP-TEST', patientId: store.patients.first.id,
        scheduledAt: due, reason: 'Contrôle',
      );
      expect(plan(DateTime(2026, 10, 11, 23, 59)).isOverdue(now), true);
      expect(plan(DateTime(2026, 10, 12, 8)).isToday(now), true);
      expect(plan(DateTime(2026, 10, 13)).isUpcoming(now), true);
      expect(plan(DateTime(2026, 10, 12, 23, 59)).isUpcoming(now), false);
    });

    test('création d’un suivi avec date, motif et notes pour le bon patient', () {
      final patientId = store.patients.first.id;
      final before = store.followUpsFor(patientId).length;
      final date = DateTime(2026, 11, 2, 14, 45);
      store.scheduleFollowUp(
        patientId: patientId, scheduledAt: date,
        reason: '  Contrôle clinique  ', notes: '  Préparer les bilans  ',
      );
      final plans = store.followUpsFor(patientId);
      expect(plans.length, before + 1);
      final created = plans.firstWhere((p) => p.scheduledAt == date);
      expect(created.reason, 'Contrôle clinique');
      expect(created.notes, 'Préparer les bilans');
      expect(created.status, FollowUpStatus.planned);
      expect(store.patientById(patientId)!.followUp, true);
    });

    test('report d’un rendez-vous et clôture sans effacer son historique', () {
      final patientId = store.patients[1].id;
      final initial = DateTime(2026, 11, 2, 10);
      store.scheduleFollowUp(
        patientId: patientId, scheduledAt: initial, reason: 'Premier motif');
      final created = store.followUpsFor(patientId).single;
      final updatedAt = DateTime(2026, 11, 5, 13);
      store.rescheduleFollowUp(
        followUpId: created.id, scheduledAt: updatedAt,
        reason: 'Motif actualisé');
      expect(store.followUpsFor(patientId).single.scheduledAt, updatedAt);
      expect(store.followUpsFor(patientId).single.reason, 'Motif actualisé');
      store.closeFollowUp(created.id, completed: true);
      expect(store.followUpsFor(patientId).single.status,
        FollowUpStatus.completed);
      expect(store.patientById(patientId)!.followUp, false);
      expect(store.pastFollowUps.any((p) => p.id == created.id), true);
      expect(() => store.closeFollowUp(created.id, completed: true),
        throwsStateError);
      expect(() => store.rescheduleFollowUp(
        followUpId: created.id, scheduledAt: initial, reason: 'Non autorisé'),
        throwsStateError);
    });

    test('une annulation conserve l’historique et libère le suivi', () {
      final id = store.patients[1].id;
      store.scheduleFollowUp(
        patientId: id, scheduledAt: DateTime(2026, 11, 2),
        reason: 'Contrôle');
      final plan = store.followUpsFor(id).single;
      store.closeFollowUp(plan.id, completed: false);
      expect(store.followUpsFor(id).single.status, FollowUpStatus.cancelled);
      expect(store.patientById(id)!.followUp, false);
    });

    test('plusieurs suivis : clôturer un seul conserve le signalement', () {
      final id = store.patients[1].id;
      store.scheduleFollowUp(
        patientId: id, scheduledAt: DateTime(2026, 11, 2),
        reason: 'Suivi 1');
      final first = store.followUpsFor(id).single;
      store.scheduleFollowUp(
        patientId: id, scheduledAt: DateTime(2026, 11, 3),
        reason: 'Suivi 2');
      store.closeFollowUp(first.id, completed: true);
      expect(store.patientById(id)!.followUp, true);
      expect(store.plannedFollowUps.any((p) => p.patientId == id), true);
    });

    test('invariants : patient et motif obligatoires', () {
      expect(() => store.scheduleFollowUp(
        patientId: 'INEXISTANT', scheduledAt: DateTime(2026, 11, 2),
        reason: 'Contrôle'), throwsStateError);
      expect(() => store.scheduleFollowUp(
        patientId: store.patients.first.id,
        scheduledAt: DateTime(2026, 11, 2),
        reason: ' '), throwsArgumentError);
    });
  });

  testWidgets('Suivi et échéances lisibles sur écran de 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DemoStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DemoScope(store: store,
      child: MaterialApp(theme: MediTheme.light(),
        home: const Scaffold(body: FollowupScreen()))));
    await tester.pumpAndSettle();
    expect(find.text('Suivi médical'), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Programmer un suivi depuis le formulaire', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DemoStore();
    addTearDown(store.dispose);
    final patientId = store.patients[1].id;
    final initialCount = store.followUpsFor(patientId).length;
    await tester.pumpWidget(DemoScope(store: store,
      child: MaterialApp(theme: MediTheme.light(),
        home: FollowUpEditorScreen(patientId: patientId))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Contrôle programmé');
    await tester.ensureVisible(find.text('Programmer le suivi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programmer le suivi').last);
    await tester.pumpAndSettle();
    expect(store.followUpsFor(patientId).length, initialCount + 1);
    expect(tester.takeException(), isNull);
  });
}
