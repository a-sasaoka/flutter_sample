import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_auth_invalidation_store.g.dart';

/// SQLite に保存されたセッション無効化状態と削除対象アカウント識別子
typedef CustomAuthInvalidationState = ({
  bool isInvalidated,
  String? targetUserId,
  String? targetEmail,
});

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
  }) : _getDirectory = getDirectory;

  final Future<Directory> Function() _getDirectory;

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
              invalidated INTEGER NOT NULL,
              target_user_id TEXT,
              target_email TEXT
            );
          ''');
        final columns = database.select(
          'PRAGMA table_info(custom_auth_invalidation);',
        );
        final columnNames = {for (final row in columns) row['name'] as String};
        if (!columnNames.contains('target_user_id')) {
          database.execute(
            'ALTER TABLE custom_auth_invalidation '
            'ADD COLUMN target_user_id TEXT;',
          );
        }
        if (!columnNames.contains('target_email')) {
          database.execute(
            'ALTER TABLE custom_auth_invalidation '
            'ADD COLUMN target_email TEXT;',
          );
        }
      },
    );
  }

  /// 削除対象アカウントと候補アカウントが一致するかを判定する
  ///
  /// 双方に `userId` がある場合は `userId` 同士を優先比較し（別アカウントによる
  /// 同一メールアドレスの再取得などを区別するため）、不足時は正規化済み `email` を
  /// 比較します。いずれでも判定できない場合は [defaultWhenUnidentifiable] を返します。
  static bool matchesAccount({
    required String? targetUserId,
    required String? targetEmail,
    required String? candidateUserId,
    required String? candidateEmail,
    required bool defaultWhenUnidentifiable,
  }) {
    if (targetUserId != null && candidateUserId != null) {
      return targetUserId == candidateUserId;
    }
    final normalizedTargetEmail = _normalizeEmail(targetEmail);
    final normalizedCandidateEmail = _normalizeEmail(candidateEmail);
    if (normalizedTargetEmail != null && normalizedCandidateEmail != null) {
      return normalizedTargetEmail == normalizedCandidateEmail;
    }
    return defaultWhenUnidentifiable;
  }

  static String? _normalizeEmail(String? email) {
    final trimmed = email?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.toLowerCase();
  }

  /// セッション無効化状態が SQLite に永続化されているかを返す
  Future<bool> isInvalidated() async {
    final state = await getInvalidationState();
    return state.isInvalidated;
  }

  /// SQLite に保存されているセッション無効化状態と対象アカウント識別子を返す
  Future<CustomAuthInvalidationState> getInvalidationState() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return (isInvalidated: false, targetUserId: null, targetEmail: null);
    }

    return await _runWithExecutor(dbFile, (executor) async {
      final rows = await executor.runSelect(
        'SELECT invalidated, target_user_id, target_email '
        'FROM custom_auth_invalidation WHERE id = 1;',
        const [],
      );
      if (rows.isEmpty || rows.first['invalidated'] != 1) {
        return (isInvalidated: false, targetUserId: null, targetEmail: null);
      }
      return (
        isInvalidated: true,
        targetUserId: rows.first['target_user_id'] as String?,
        targetEmail: rows.first['target_email'] as String?,
      );
    });
  }

  /// セッション無効化状態を削除対象アカウント情報とともに SQLite へ確定保存する
  Future<void> markInvalidated({
    String? targetUserId,
    String? targetEmail,
  }) async {
    final dir = await _getDirectory();
    await dir.create(recursive: true);
    final dbFile = File(p.join(dir.path, databaseFileName));

    await _runWithExecutor(dbFile, (executor) async {
      await executor.runInsert(
        'INSERT OR REPLACE INTO custom_auth_invalidation '
        '(id, invalidated, target_user_id, target_email) VALUES (1, 1, ?, ?);',
        [targetUserId, _normalizeEmail(targetEmail)],
      );
    });
  }

  /// ログイン完了時に、進行中の退会処理が無い状態で別アカウントがログインした場合のみ無効化レコードを解除する
  ///
  /// 進行中の退会処理が存在する場合や、同一アカウント時はレコードを保持して `false` を返し、
  /// 退会処理が進行中でない別アカウント（または元々未無効化）だった場合のみ解除して `true` を返します。
  Future<bool> clearIfAllowedForLogin({
    required String? userId,
    required String? email,
    required bool isDeletionInProgress,
  }) async {
    final state = await getInvalidationState();
    if (!state.isInvalidated) {
      return true;
    }

    if (isDeletionInProgress) {
      // 進行中の退会処理が所有している無効化レコードは別アカウントのログイン時でも削除しない
      return false;
    }

    final blockedBySameAccount = matchesAccount(
      targetUserId: state.targetUserId,
      targetEmail: state.targetEmail,
      candidateUserId: userId,
      candidateEmail: email,
      defaultWhenUnidentifiable: false,
    );
    if (blockedBySameAccount) {
      return false;
    }

    await clearInvalidated();
    return true;
  }

  /// 保存済みの無効化レコードが指定アカウント（[targetUserId] / [targetEmail]）の
  /// ものと一致する場合のみ解除する
  Future<void> clearInvalidatedIfMatches({
    required String? targetUserId,
    required String? targetEmail,
  }) async {
    final state = await getInvalidationState();
    if (!state.isInvalidated) {
      return;
    }
    if (state.targetUserId != targetUserId ||
        state.targetEmail != _normalizeEmail(targetEmail)) {
      return;
    }
    await clearInvalidated();
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
    final executor = createDurableDatabase(dbFile);
    try {
      await executor.ensureOpen(const _StoreQueryExecutorUser());
      return await action(executor);
    } finally {
      await executor.close();
    }
  }
}
