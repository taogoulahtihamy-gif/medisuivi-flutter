// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'followup_dao.dart';

// ignore_for_file: type=lint
mixin _$FollowUpDaoMixin on DatabaseAccessor<AppDatabase> {
  $FollowUpsTable get followUps => attachedDatabase.followUps;
  FollowUpDaoManager get managers => FollowUpDaoManager(this);
}

class FollowUpDaoManager {
  final _$FollowUpDaoMixin _db;
  FollowUpDaoManager(this._db);
  $$FollowUpsTableTableManager get followUps =>
      $$FollowUpsTableTableManager(_db.attachedDatabase, _db.followUps);
}
