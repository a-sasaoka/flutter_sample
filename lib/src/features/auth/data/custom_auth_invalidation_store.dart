import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_auth_invalidation_store.g.dart';

/// SQLite の [QueryExecutor] を生成するファクトリ関数型
typedef QueryExecutorFactory = QueryExecutor Function(File databaseFile);

class _StoreQueryExecutorUser implements QueryExecutorUser {
  const _StoreQueryExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

// coverage:ignore-start
/// アプリケーションサポートディレクトリを取得する関数を提供するプロバイダ
///
/// テスト時は一時ディレクトリを返す関数で差し替えることで、実ファイルシステム上で
/// 永続化・復旧処理を検証できます。
@Riverpod(keepAlive: true)
Future<Directory> Function() appSupportDirectoryReader(Ref ref) {
  return getApplicationSupportDirectory;
}
// coverage:ignore-end

/// [CustomAuthInvalidationStore] のプロバイダ
@Riverpod(keepAlive: true)
CustomAuthInvalidationStore customAuthInvalidationStore(Ref ref) {
  return CustomAuthInvalidationStore(
    getDirectory: ref.watch(appSupportDirectoryReaderProvider),
  );
}

/// カスタム認証の退会に伴うセッション無効化状態を専用 SQLite DB へ永続化するストア
///
/// メモ用 `AppDatabase` とは独立した SQLite ファイルに
/// `PRAGMA journal_mode = DELETE`・`PRAGMA synchronous = EXTRA`・
/// `PRAGMA fullfsync = ON` を設定して保存することで、Android の親ディレクトリ
/// `fsync` および iOS の `F_FULLFSYNC` を含む SQLite のトランザクション永続化
/// 保証（ACID）を利用して完了時点でのディスク永続化を確保します。
class CustomAuthInvalidationStore {
  /// [CustomAuthInvalidationStore] を生成する
  CustomAuthInvalidationStore({
    required Future<Directory> Function() getDirectory,
    @visibleForTesting QueryExecutorFactory? createExecutor,
  }) : _getDirectory = getDirectory,
       _createExecutor = createExecutor ?? createDurableDatabase;

  final Future<Directory> Function() _getDirectory;
  final QueryExecutorFactory _createExecutor;

  /// 永続化に使用する専用 SQLite データベースファイル名
  @visibleForTesting
  static const databaseFileName = 'custom_auth_invalidation.sqlite';

  /// 最大耐久設定を有効にした専用 SQLite エグゼキュータを生成する
  @visibleForTesting
  static QueryExecutor createDurableDatabase(File databaseFile) {
    return NativeDatabase(
      databaseFile,
      enableMigrations: false,
      setup: (database) {
        database
          ..execute('PRAGMA busy_timeout = 5000;')
          ..execute('PRAGMA journal_mode = DELETE;')
          ..execute('PRAGMA synchronous = EXTRA;')
          ..execute('PRAGMA fullfsync = ON;')
          ..execute('''
            CREATE TABLE IF NOT EXISTS custom_auth_invalidation (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              invalidated INTEGER NOT NULL
            );
          ''');
      },
    );
  }

  /// セッション無効化状態が SQLite に永続化されているかを返す
  Future<bool> isInvalidated() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return false;
    }

    return await _runWithExecutor(dbFile, (executor) async {
      final rows = await executor.runSelect(
        'SELECT invalidated FROM custom_auth_invalidation WHERE id = 1;',
        const [],
      );
      return rows.isNotEmpty && rows.first['invalidated'] == 1;
    });
  }

  /// セッション無効化状態を SQLite トランザクションとしてディスクへ確定保存する
  Future<void> markInvalidated() async {
    final dir = await _getDirectory();
    await dir.create(recursive: true);
    final dbFile = File(p.join(dir.path, databaseFileName));

    await _runWithExecutor(dbFile, (executor) async {
      await executor.runInsert(
        'INSERT OR REPLACE INTO custom_auth_invalidation '
        '(id, invalidated) VALUES (1, 1);',
        const [],
      );
    });
  }

  /// SQLite 上のセッション無効化レコードを削除して確定保存する
  Future<void> clearInvalidated() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return;
    }

    await _runWithExecutor(dbFile, (executor) async {
      await executor.runDelete(
        'DELETE FROM custom_auth_invalidation WHERE id = 1;',
        const [],
      );
    });
  }

  Future<T> _runWithExecutor<T>(
    File dbFile,
    Future<T> Function(QueryExecutor executor) action,
  ) async {
    final executor = _createExecutor(dbFile);
    try {
      await executor.ensureOpen(const _StoreQueryExecutorUser());
      return await action(executor);
    } finally {
      await executor.close();
    }
  }
}
