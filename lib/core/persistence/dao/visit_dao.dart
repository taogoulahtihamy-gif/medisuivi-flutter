/// DAO pour la table Visits
library;

import 'package:drift/drift.dart';

import '../database.dart';

part 'visit_dao.g.dart';

@DriftAccessor(tables: [Visits])
class VisitDao extends DatabaseAccessor<AppDatabase> with _$VisitDaoMixin {
  VisitDao(super.db);

  /// Insère une nouvelle visite
  Future<void> createVisit({
    required String patientId,
    required String reason,
    double? temperature,
    int? systolic,
    int? diastolic,
    int? pulse,
    int? spo2,
    String notes = '',
  }) async {
    final id = generateId();
    final now = DateTime.now().toUtc();
    await into(visits).insert(VisitsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      date: Value(now),
      reason: Value(reason),
      temperature: temperature != null ? Value(temperature) : const Value.absent(),
      systolic: systolic != null ? Value(systolic) : const Value.absent(),
      diastolic: diastolic != null ? Value(diastolic) : const Value.absent(),
      pulse: pulse != null ? Value(pulse) : const Value.absent(),
      spo2: spo2 != null ? Value(spo2) : const Value.absent(),
      notes: Value(notes),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Récupère toutes les visites d'un patient (les plus récentes d'abord)
  Future<List<Visit>> getVisitsForPatient(String patientId) {
    return (select(visits)
          ..where((v) => v.patientId.equals(patientId))
          ..orderBy([(v) => OrderingTerm.desc(v.date)]))
        .get();
  }

  /// Stream réactif des visites d'un patient
  Stream<List<Visit>> watchVisitsForPatient(String patientId) {
    return (select(visits)
          ..where((v) => v.patientId.equals(patientId))
          ..orderBy([(v) => OrderingTerm.desc(v.date)]))
        .watch();
  }

  /// Récupère la dernière visite d'un patient
  Future<Visit?> getLastVisitForPatient(String patientId) {
    return (select(visits)
          ..where((v) => v.patientId.equals(patientId))
          ..orderBy([(v) => OrderingTerm.desc(v.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Met à jour une visite
  Future<void> updateVisit(VisitsCompanion companion) async {
    await update(visits).replace(companion);
  }

  /// Supprime une visite
  Future<void> deleteVisit(String visitId) async {
    await (delete(visits)..where((v) => v.id.equals(visitId))).go();
  }

  /// Récupère toutes les visites (pour initialisation cache)
  Future<List<Visit>> getVisitsForAllPatients() {
    return (select(visits)..orderBy([(v) => OrderingTerm.desc(v.date)])).get();
  }

  /// Stream réactif de toutes les visites
  Stream<List<Visit>> watchAllVisits() {
    return (select(visits)..orderBy([(v) => OrderingTerm.desc(v.date)])).watch();
  }
}