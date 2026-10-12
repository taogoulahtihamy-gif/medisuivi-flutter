// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_dao.dart';

// ignore_for_file: type=lint
mixin _$ExamDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExamsTable get exams => attachedDatabase.exams;
  ExamDaoManager get managers => ExamDaoManager(this);
}

class ExamDaoManager {
  final _$ExamDaoMixin _db;
  ExamDaoManager(this._db);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
}
