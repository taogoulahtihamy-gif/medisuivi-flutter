/// DAO pour la table FollowUps
library;

import 'dart:convert';
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
    await attachedDatabase.transaction(() async {
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
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'followup',
        entityId: id,
        operationType: 'create',
        payload: jsonEncode({
          'id': id, 'patientId': patientId,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          'reason': reason, 'notes': notes, 'status': 0,
        }),
        baseRevision: 0,
      );
    });
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

  /// Reporte un suivi non clôturé et inscrit son opération durable.
  Future<void> rescheduleFollowUp({
    required String followUpId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    final now = DateTime.now().toUtc();
    await attachedDatabase.transaction(() async {
      final existing = await (select(followUps)
        ..where((f) => f.id.equals(followUpId))).getSingleOrNull();
      if (existing == null) throw StateError('Suivi introuvable.');
      if (existing.status != 0) {
        throw StateError('Un suivi terminé ne peut pas être modifié.');
      }
      await (update(followUps)..where((f) => f.id.equals(followUpId))).write(
        FollowUpsCompanion(
          scheduledAt: Value(scheduledAt.toUtc()),
          reason: Value(reason),
          notes: Value(notes),
          updatedAt: Value(now),
        ),
      );
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'followup',
        entityId: followUpId,
        operationType: 'update',
        payload: jsonEncode({
          'id': followUpId,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          'reason': reason, 'notes': notes,
        }),
        baseRevision: 0,
      );
    });
  }

  /// Clôture un suivi et conserve la trace de la modification.
  Future<void> closeFollowUp({
    required String followUpId,
    required bool completed,
  }) async {
    final now = DateTime.now().toUtc();
    await attachedDatabase.transaction(() async {
      final existing = await (select(followUps)
        ..where((f) => f.id.equals(followUpId))).getSingleOrNull();
      if (existing == null) throw StateError('Suivi introuvable.');
      if (existing.status != 0) throw StateError('Ce suivi est déjà clôturé.');
      await (update(followUps)..where((f) => f.id.equals(followUpId))).write(
        FollowUpsCompanion(
          status: Value(completed ? 1 : 2),
          completedAt: completed ? Value(now) : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'followup',
        entityId: followUpId,
        operationType: 'update',
        payload: jsonEncode({
          'id': followUpId, 'status': completed ? 1 : 2,
          'completedAt': completed ? now.toIso8601String() : null,
        }),
        baseRevision: 0,
      );
    });
  }

  /// Utiliser closeFollowUp(completed: false) pour annuler avec traçabilité.
  Future<void> deleteFollowUp(String followUpId) async {
    throw UnsupportedError(
      'La suppression d’un suivi est bloquée : annulez-le de façon tracée.',
    );
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