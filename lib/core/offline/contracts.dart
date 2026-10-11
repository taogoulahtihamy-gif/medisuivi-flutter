/// Contrats préparatoires. AUCUNE synchronisation réseau ou donnée
/// médicale réelle n'est activée dans le prototype.
/// Architecture détaillée : docs/OFFLINE_SYNC.md.
enum SyncState { notConfigured, offline, pending, syncing, synced, failed, conflict }

class PendingOperation {
  const PendingOperation({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.baseRevision,
    required this.timestamp,
  });

  final String operationId;
  final String entityType;
  final String entityId;
  final int baseRevision;
  final DateTime timestamp;
}

abstract interface class LocalMedicalRepository {
  /// Lecture depuis une base locale CHIFFREE sur l'appareil.
  Future<void> initialize();
  Future<List<PendingOperation>> pendingOperations();
  Future<void> acknowledge(String operationId, int serverRevision);
}

abstract interface class RemoteSyncGateway {
  /// Les requêtes devront être authentifiées, idempotentes et TLS uniquement.
  Future<int> push(PendingOperation operation);
}
