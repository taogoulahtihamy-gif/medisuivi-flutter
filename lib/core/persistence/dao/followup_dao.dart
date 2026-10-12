/// DAO pour la table FollowUps
library;

import 'package:drift/drift.dart';

import '../database.dart';

part 'followup_dao.g.dart';

@DriftAccessor(tables: [FollowUps])
class FollowUpDao extends DatabaseAccessor<AppDatabase> with _$FollowUpDaoMixin {
  FollowUpDao(super.db);

  /// Programme un nouveau suivi
  Future<void> scheduleFollowUp({
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    final id = generateId();
    final now = DateTime.now().toUtc();
    await into(followUps).insert(FollowUpsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      scheduledAt: Value(scheduledAt.toUtc()),
      reason: Value(reason),
      notes: Value(notes),
      status: const Value(0), // planned
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Récupère les suivis planifiés (futurs)
  Future<List<FollowUp>> getPlannedFollowUps() {
    final now = DateTime.now().toUtc();
    return (select(followUps)
          ..where((f) => f.status.equals(0) & f.scheduledAt.isBiggerOrEqualValue(now))
          ..orderBy([(f) => OrderingTerm.asc(f.scheduledAt)]))
        .get();
  }

  /// Stream réactif des suivis planifiés
  Stream<List<FollowUp>> watchPlannedFollowUps() {
    final now = DateTime.now().toUtc();
    return (select(followUps)
          ..where((f) => f.status.equals(0) & f.scheduledAt.isBiggerOrEqualValue(now))
          ..orderBy([(f) => OrderingTerm.asc(f.scheduledAt)]))
        .watch();
  }

  /// Récupère les suivis passés (historique)
  Future<List<FollowUp>> getPastFollowUps() {
    final now = DateTime.now().toUtc();
    return (select(followUps)
          ..where((f) => f.status.equals(0).not() | f.scheduledAt.isSmallerThanValue(now))
          ..orderBy([(f) => OrderingTerm.desc(f.scheduledAt)]))
        .get();
  }

  /// Stream réactif des suivis passés
  Stream<List<FollowUp>> watchPastFollowUps() {
    final now = DateTime.now().toUtc();
    return (select(followUps)
          ..where((f) => f.status.equals(0).not() | f.scheduledAt.isSmallerThanValue(now))
          ..orderBy([(f) => OrderingTerm.desc(f.scheduledAt)]))
        .watch();
  }

  /// Récupère les suivis d'un patient
  Future<List<FollowUp>> getFollowUpsForPatient(String patientId) {
    return (select(followUps)
          ..where((f) => f.patientId.equals(patientId))
          ..orderBy([(f) => OrderingTerm.desc(f.scheduledAt)]))
        .get();
  }

  /// Stream réactif des suivis d'un patient
  Stream<List<FollowUp>> watchFollowUpsForPatient(String patientId) {
    return (select(followUps)
          ..where((f) => f.patientId.equals(patientId))
          ..orderBy([(f) => OrderingTerm.desc(f.scheduledAt)]))
        .watch();
  }

  /// Reporte un suivi
  Future<void> rescheduleFollowUp({
    required String followUpId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    final now = DateTime.now().toUtc();
    await (update(followUps)..where((f) => f.id.equals(followUpId))).write(
      FollowUpsCompanion(
        scheduledAt: Value(scheduledAt.toUtc()),
        reason: Value(reason),
        notes: Value(notes),
        updatedAt: Value(now),
      ),
    );
  }

  /// Clôture un suivi (completed ou cancelled)
  Future<void> closeFollowUp({
    required String followUpId,
    required bool completed,
  }) async {
    final now = DateTime.now().toUtc();
    await (update(followUps)..where((f) => f.id.equals(followUpId))).write(
      FollowUpsCompanion(
        status: Value(completed ? 1 : 2), // completed : cancelled
        completedAt: completed ? Value(now) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  /// Supprime un suivi
  Future<void> deleteFollowUp(String followUpId) async {
    await (delete(followUps)..where((f) => f.id.equals(followUpId))).go();
  }

  /// Récupère tous les suivis (pour initialisation cache)
  Future<List<FollowUp>> getAllFollowUps() {
    return (select(followUps)..orderBy([(f) => OrderingTerm.desc(f.scheduledAt)])).get();
  }

  /// Stream réactif de tous les suivis
  Stream<List<FollowUp>> watchAllFollowUps() {
    return (select(followUps)..orderBy([(f) => OrderingTerm.desc(f.scheduledAt)])).watch();
  }
}