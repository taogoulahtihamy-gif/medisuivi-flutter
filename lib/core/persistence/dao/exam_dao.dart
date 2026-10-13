/// DAO pour la table Exams
library;

import 'dart:convert';
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
    await attachedDatabase.transaction(() async {
      await into(exams).insert(ExamsCompanion(
        id: Value(id),
        patientId: Value(patientId),
        title: Value(title),
        date: Value(now),
        status: const Value(0), // pending
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'exam',
        entityId: id,
        operationType: 'create',
        payload: jsonEncode({
          'id': id, 'patientId': patientId, 'title': title,
          'status': 0, 'date': now.toIso8601String(),
        }),
        baseRevision: 0,
      );
    });
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
    await attachedDatabase.transaction(() async {
      final exam = await getExamById(examId);
      if (exam == null) throw StateError('Examen introuvable.');
      if (exam.status == 1) throw StateError('Ce bilan possède déjà un résultat.');
      if (result.trim().isEmpty) throw ArgumentError('Résultat obligatoire.');

      await (update(exams)..where((e) => e.id.equals(examId))).write(
        ExamsCompanion(
          status: const Value(1),
          result: Value(result.trim()),
          resultRecordedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await attachedDatabase.pendingOperationsDao.addOperation(
        operationId: generateId(),
        entityType: 'exam',
        entityId: examId,
        operationType: 'update',
        payload: jsonEncode({
          'id': examId, 'status': 1, 'result': result.trim(),
          'resultRecordedAt': now.toIso8601String(),
        }),
        baseRevision: 0,
      );
    });
  }

  /// Un résultat clinique ne doit jamais être modifié par remplacement brut.
  Future<void> updateExam(ExamsCompanion companion) async {
    throw UnsupportedError(
      'La rectification d’un examen nécessite une piste d’audit.',
    );
  }

  /// Suppression bloquée jusqu'à implémentation des rectificatifs et tombstones.
  Future<void> deleteExam(String examId) async {
    throw UnsupportedError(
      'La suppression d’un examen nécessite une procédure tracée.',
    );
  }
}