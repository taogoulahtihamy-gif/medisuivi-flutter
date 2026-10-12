/// DAO pour la table Patients
library;

import 'dart:convert';
import 'package:drift/drift.dart';

import '../database.dart';

part 'patient_dao.g.dart';

@DriftAccessor(tables: [Patients])
class PatientDao extends DatabaseAccessor<AppDatabase> with _$PatientDaoMixin {
  PatientDao(super.db);

  /// Insère un nouveau patient
  Future<void> createPatient({
    required String name,
    required int age,
    required String sex,
    required String phone,
  }) async {
    final id = generateId();
    final now = DateTime.now().toUtc();
    await attachedDatabase.transaction(() async {
      await into(patients).insert(PatientsCompanion(
        id: Value(id),
        name: Value(name),
        age: Value(age),
        sex: Value(sex),
        phone: Value(phone),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'patient',
        entityId: id,
        operationType: 'create',
        payload: jsonEncode({
          'id': id, 'name': name, 'age': age, 'sex': sex, 'phone': phone,
          'createdAt': now.toIso8601String(), 'updatedAt': now.toIso8601String(),
        }),
        baseRevision: 0,
      );
    });
  }

  /// Récupère un patient par ID
  Future<Patient?> getPatientById(String id) {
    return (select(patients)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Récupère tous les patients
  Future<List<Patient>> getAllPatients() {
    return select(patients).get();
  }

  /// Stream réactif de tous les patients (triés par nom)
  Stream<List<Patient>> watchAllPatients() {
    return (select(patients)..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();
  }

  /// Stream réactif des patients marqués pour suivi
  Stream<List<Patient>> watchPatientsForFollowUp() {
    return (select(patients)
          ..where((p) => p.followUp.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Met à jour les informations médicales d'un patient
  Future<void> updatePatientInfo({
    required String patientId,
    required String phone,
    required String allergies,
    required String medicalHistory,
  }) async {
    final now = DateTime.now().toUtc();
    await attachedDatabase.transaction(() async {
      final patient = await getPatientById(patientId);
      if (patient == null) throw StateError('Dossier patient introuvable.');
      await (update(patients)..where((p) => p.id.equals(patientId))).write(
        PatientsCompanion(
          phone: Value(phone),
          allergies: Value(allergies),
          medicalHistory: Value(medicalHistory),
          updatedAt: Value(now),
        ),
      );
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'patient',
        entityId: patientId,
        operationType: 'update',
        payload: jsonEncode({
          'id': patientId, 'phone': phone, 'allergies': allergies,
          'medicalHistory': medicalHistory, 'updatedAt': now.toIso8601String(),
        }),
        baseRevision: 0,
      );
    });
  }

  /// Active/désactive le drapeau de suivi
  Future<void> setFollowUp(String patientId, {required bool toReview}) async {
    final now = DateTime.now().toUtc();
    await attachedDatabase.transaction(() async {
      final patient = await getPatientById(patientId);
      if (patient == null) throw StateError('Dossier patient introuvable.');
      await (update(patients)..where((p) => p.id.equals(patientId))).write(
        PatientsCompanion(
          followUp: Value(toReview),
          updatedAt: Value(now),
        ),
      );
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'patient',
        entityId: patientId,
        operationType: 'update',
        payload: jsonEncode({
          'id': patientId, 'followUp': toReview,
          'updatedAt': now.toIso8601String(),
        }),
        baseRevision: 0,
      );
    });
  }

  /// Supprime un patient (et ses données liées via triggers ou manuellement)
  Future<void> deletePatient(String patientId) async {
    await (delete(patients)..where((p) => p.id.equals(patientId))).go();
  }
}