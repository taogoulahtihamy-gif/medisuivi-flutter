/// DAO pour la table Exams
library;

import 'package:drift/drift.dart';

import '../database.dart';

part 'exam_dao.g.dart';

@DriftAccessor(tables: [Exams])
class ExamDao extends DatabaseAccessor<AppDatabase> with _$ExamDaoMixin {
  ExamDao(super.db);

  /// Crée un nouvel examen (prescription) et retourne son ID
  Future<String> createExam({
    required String patientId,
    required String title,
  }) async {
    final id = generateId();
    final now = DateTime.now().toUtc();
    await into(exams).insert(ExamsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      title: Value(title),
      date: Value(now),
      status: const Value(0), // pending
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    return id;
  }

  /// Récupère un examen par ID
  Future<Exam?> getExamById(String examId) {
    return (select(exams)..where((e) => e.id.equals(examId))).getSingleOrNull();
  }

  /// Récupère tous les examens
  Future<List<Exam>> getAllExams() {
    return (select(exams)..orderBy([(e) => OrderingTerm.desc(e.date)])).get();
  }

  /// Stream réactif de tous les examens
  Stream<List<Exam>> watchAllExams() {
    return (select(exams)..orderBy([(e) => OrderingTerm.desc(e.date)])).watch();
  }

  /// Récupère les examens d'un patient
  Future<List<Exam>> getExamsForPatient(String patientId) {
    return (select(exams)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  /// Stream réactif des examens d'un patient
  Stream<List<Exam>> watchExamsForPatient(String patientId) {
    return (select(exams)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  /// Stream réactif des examens en attente
  Stream<List<Exam>> watchPendingExams() {
    return (select(exams)
          ..where((e) => e.status.equals(0))
          ..orderBy([(e) => OrderingTerm.asc(e.date)]))
        .watch();
  }

  /// Compte les examens en attente
  Future<int> countPendingExams() {
    return (select(exams)..where((e) => e.status.equals(0))).get().then((list) => list.length);
  }

  /// Enregistre le résultat d'un examen
  Future<void> recordExamResult({
    required String examId,
    required String result,
  }) async {
    final now = DateTime.now().toUtc();
    await (update(exams)..where((e) => e.id.equals(examId))).write(
      ExamsCompanion(
        status: const Value(1), // complete
        result: Value(result),
        resultRecordedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Met à jour un examen
  Future<void> updateExam(ExamsCompanion companion) async {
    await update(exams).replace(companion);
  }

  /// Supprime un examen
  Future<void> deleteExam(String examId) async {
    await (delete(exams)..where((e) => e.id.equals(examId))).go();
  }
}