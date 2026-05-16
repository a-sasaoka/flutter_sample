// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memos_dao.dart';

// ignore_for_file: type=lint
mixin _$MemosDaoMixin on DatabaseAccessor<AppDatabase> {
  $MemosTable get memos => attachedDatabase.memos;
  MemosDaoManager get managers => MemosDaoManager(this);
}

class MemosDaoManager {
  final _$MemosDaoMixin _db;
  MemosDaoManager(this._db);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db.attachedDatabase, _db.memos);
}
