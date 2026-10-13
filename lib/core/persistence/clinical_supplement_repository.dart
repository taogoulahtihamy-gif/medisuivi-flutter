/// Données complémentaires cliniques dans deux tables SQLite additives v2.
///
/// Les DAOs doivent enclore les écritures avec la mutation principale et son
/// outbox dans UNE transaction. La lecture reste locale, jamais distante.
library;
import 'dart:convert';
import 'package:drift/drift.dart' show Variable;
import '../models/clinical_intake.dart';
import 'database.dart';

class ClinicalSupplementRepository {
  const ClinicalSupplementRepository(this.database);
  final AppDatabase database;

  Future<PatientProfileSupplement?> patientProfile(String id) async {
    final rows = await database.customSelect(
      'SELECT payload FROM patient_supplements WHERE patient_id = ?',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) return null;
    return PatientProfileSupplement.fromJson(
      jsonDecode(rows.single.read<String>('payload')) as Map<String, dynamic>,
    );
  }

  /// À appeler uniquement dans la transaction patient + outbox.
  Future<void> writePatientProfile(String id, PatientProfileSupplement profile) async {
    await database.customStatement('''
      INSERT INTO patient_supplements (patient_id, payload, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(patient_id) DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
    ''', [id, jsonEncode(profile.toJson()), DateTime.now().toUtc().toIso8601String()]);
  }

  Future<ClinicalIntake?> visitIntake(String id) async {
    final rows = await database.customSelect(
      'SELECT payload FROM visit_intakes WHERE visit_id = ?',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) return null;
    return ClinicalIntake.fromJson(
      jsonDecode(rows.single.read<String>('payload')) as Map<String, dynamic>,
    );
  }

  /// INSERT strict : une consultation déjà consignée n'est pas réécrite.
  /// À appeler uniquement dans la transaction visite + outbox.
  Future<void> insertVisitIntake(String id, ClinicalIntake intake) async {
    final errors = intake.validate();
    if (errors.isNotEmpty) throw ArgumentError(errors.join(' '));
    await database.customStatement('''
      INSERT INTO visit_intakes (visit_id, payload, created_at)
      VALUES (?, ?, ?)
    ''', [id, jsonEncode(intake.toJson()), DateTime.now().toUtc().toIso8601String()]);
  }
}
