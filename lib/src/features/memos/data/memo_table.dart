// coverage:ignore-file
import 'package:drift/drift.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';

/// メモのテーブル
class Memos extends Table {
  /// メモの番号（複数の端末で被らないように、UUIDにする）
  TextColumn get id => text()();

  /// メモの所有ユーザーID
  TextColumn get userId => text()();

  /// メモのタイトル
  TextColumn get title => text()();

  /// メモの中身
  TextColumn get content => text()();

  /// 作成した日時
  DateTimeColumn get createdAt => dateTime()();

  /// 最後に更新した日時（複数の端末で同時に編集された時、新しい方を優先するため）
  DateTimeColumn get updatedAt => dateTime()();

  /// 削除フラグ
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// サーバーへ保存（同期）されたかどうかのフラグ
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// メモのカテゴリ（enumで型安全に管理。未設定はnull）
  TextColumn get category => textEnum<MemoCategory>().nullable()();

  /// メモの並び順（0が一番上。昇順でソートする）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id}; // idを主キー（メインの目印）にする
}
