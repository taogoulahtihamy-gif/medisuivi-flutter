/// DAO pour la table PendingOperations (outbox pour sync future)
library;

import 'package:drift/drift.dart';

import '../database.dart';

part 'pending_operations_dao.g.dart';

@DriftAccessor(tables: [PendingOperations])
class PendingOperationsDao extends DatabaseAccessor<AppDatabase> with _$PendingOperationsDaoMixin {
  PendingOperationsDao(super.db);

  /// Ajoute une opération en attente
  Future<void> addOperation({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payload,
    required int baseRevision,
  }) async {
    final now = DateTime.now().toUtc();
    await into(pendingOperations).insert(PendingOperationsCompanion(
      operationId: Value(operationId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operationType: Value(operationType),
      payload: Value(payload),
      baseRevision: Value(baseRevision),
      timestamp: Value(now),
      status: const Value(0), // pending
      retryCount: const Value(0),
    ));
  }

  /// Récupère toutes les opérations en attente
  Future<List<PendingOperation>> getPendingOperations() {
    return (select(pendingOperations)
          ..where((o) => o.status.equals(0))
          ..orderBy([(o) => OrderingTerm.asc(o.timestamp)]))
        .get();
  }

  /// Stream réactif des opérations en attente
  Stream<List<PendingOperation>> watchPendingOperations() {
    return (select(pendingOperations)
          ..where((o) => o.status.equals(0))
          ..orderBy([(o) => OrderingTerm.asc(o.timestamp)]))
        .watch();
  }

  /// Marque une opération comme synchronisée
  Future<void> markSynced(String operationId, int serverRevision) async {
    await (update(pendingOperations)..where((o) => o.operationId.equals(operationId))).write(
      PendingOperationsCompanion(
        status: Value(1), // synced
        baseRevision: Value(serverRevision),
      ),
    );
  }

  /// Marque une opération comme échouée
  Future<void> markFailed(String operationId) async {
    final now = DateTime.now().toUtc();
    // Lire le compteur actuel pour l'incrémenter
    final current = await (select(pendingOperations)..where((o) => o.operationId.equals(operationId))).getSingleOrNull();
    final nextRetryCount = (current?.retryCount ?? 0) + 1;
    
    await (update(pendingOperations)..where((o) => o.operationId.equals(operationId))).write(
      PendingOperationsCompanion(
        status: Value(2), // failed
        lastAttemptAt: Value(now),
        retryCount: Value(nextRetryCount),
      ),
    );
  }

  /// Marque une opération comme en conflit
  Future<void> markConflict(String operationId) async {
    await (update(pendingOperations)..where((o) => o.operationId.equals(operationId))).write(
      PendingOperationsCompanion(status: Value(3)), // conflict
    );
  }

  /// Incrémente le compteur de tentative
  Future<void> incrementRetryCount(String operationId) async {
    final now = DateTime.now().toUtc();
    final current = await (select(pendingOperations)..where((o) => o.operationId.equals(operationId))).getSingleOrNull();
    final nextRetryCount = (current?.retryCount ?? 0) + 1;
    
    await (update(pendingOperations)..where((o) => o.operationId.equals(operationId))).write(
      PendingOperationsCompanion(
        retryCount: Value(nextRetryCount),
        lastAttemptAt: Value(now),
      ),
    );
  }

  /// Supprime les anciennes opérations synchronisées (nettoyage)
  Future<void> cleanupSyncedOperations({int olderThanDays = 30}) async {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: olderThanDays));
    await (delete(pendingOperations)
          ..where((o) => o.status.equals(1) & o.timestamp.isSmallerThanValue(cutoff)))
        .go();
  }
}