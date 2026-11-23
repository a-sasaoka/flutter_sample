import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_auth_invalidation_store.g.dart';

/// アカウント識別子の照合結果
enum AccountMatch {
  /// 同一アカウントと判定できた
  same,

  /// 異なるアカウントと判定できた
  different,

  /// 識別情報が不足しており同一・別のいずれも判定できなかった
  unknown,
}

/// SQLite に保存された個別の削除対象アカウント識別子
typedef CustomAuthInvalidationEntry = ({
  String? targetUserId,
  String? targetEmail,
});

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
            CREATE TABLE IF NOT EXISTS custom_auth_invalidation_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              target_user_id TEXT,
              target_email TEXT
            );
          ''')
          ..execute('''
            CREATE TABLE IF NOT EXISTS custom_auth_pending_login (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              pending INTEGER NOT NULL
            );
          ''');
        // 旧 1 行テーブルが存在する場合はデータを新テーブルへ移行して破棄する
        final legacyTables = database.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'custom_auth_invalidation';",
        );
        if (legacyTables.isNotEmpty) {
          final columns = database.select(
            'PRAGMA table_info(custom_auth_invalidation);',
          );
          final columnNames = {
            for (final row in columns) row['name'] as String,
          };
          final hasIdentifierColumns =
              columnNames.contains('target_user_id') &&
              columnNames.contains('target_email');
          final legacyRows = database.select(
            hasIdentifierColumns
                ? 'SELECT invalidated, target_user_id, target_email '
                      'FROM custom_auth_invalidation WHERE id = 1;'
                : 'SELECT invalidated, NULL AS target_user_id, '
                      'NULL AS target_email '
                      'FROM custom_auth_invalidation WHERE id = 1;',
          );
          if (legacyRows.isNotEmpty && legacyRows.first['invalidated'] == 1) {
            database.execute(
              'INSERT INTO custom_auth_invalidation_entries '
              '(target_user_id, target_email) VALUES (?, ?);',
              [
                legacyRows.first['target_user_id'] as String?,
                _normalizeEmail(legacyRows.first['target_email'] as String?),
              ],
            );
          }
          database.execute('DROP TABLE custom_auth_invalidation;');
        }
      },
    );
  }

  /// 削除対象アカウントと候補アカウントを照合し、同一・別・判定不能の 3 値を返す
  ///
  /// 双方に `userId` がある場合は `userId` 同士を優先比較し（別アカウントによる
  /// 同一メールアドレスの再取得などを区別するため）、不足時は正規化済み `email` を
  /// 比較します。いずれでも判定できない場合は [AccountMatch.unknown] を返します。
  static AccountMatch compareAccounts({
    required String? targetUserId,
    required String? targetEmail,
    required String? candidateUserId,
    required String? candidateEmail,
  }) {
    if (targetUserId != null && candidateUserId != null) {
      return targetUserId == candidateUserId
          ? AccountMatch.same
          : AccountMatch.different;
    }
    final normalizedTargetEmail = _normalizeEmail(targetEmail);
    final normalizedCandidateEmail = _normalizeEmail(candidateEmail);
    if (normalizedTargetEmail != null && normalizedCandidateEmail != null) {
      return normalizedTargetEmail == normalizedCandidateEmail
          ? AccountMatch.same
          : AccountMatch.different;
    }
    return AccountMatch.unknown;
  }

  /// 削除対象アカウントと候補アカウントが一致するかを判定する
  ///
  /// [compareAccounts] の結果に基づき、判定不能時は [defaultWhenUnidentifiable] を返します。
  static bool matchesAccount({
    required String? targetUserId,
    required String? targetEmail,
    required String? candidateUserId,
    required String? candidateEmail,
    required bool defaultWhenUnidentifiable,
  }) {
    return switch (compareAccounts(
      targetUserId: targetUserId,
      targetEmail: targetEmail,
      candidateUserId: candidateUserId,
      candidateEmail: candidateEmail,
    )) {
      AccountMatch.same => true,
      AccountMatch.different => false,
      AccountMatch.unknown => defaultWhenUnidentifiable,
    };
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
    final entries = await getInvalidationEntries();
    return entries.isNotEmpty;
  }

  /// SQLite に保存されているすべての削除対象アカウント識別子を返す
  Future<List<CustomAuthInvalidationEntry>> getInvalidationEntries() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return const [];
    }

    return await _runWithExecutor(dbFile, (executor) async {
      final rows = await executor.runSelect(
        'SELECT target_user_id, target_email '
        'FROM custom_auth_invalidation_entries ORDER BY id ASC;',
        const [],
      );
      return [
        for (final row in rows)
          (
            targetUserId: row['target_user_id'] as String?,
            targetEmail: row['target_email'] as String?,
          ),
      ];
    });
  }

  /// SQLite に保存されている最新のセッション無効化状態と対象アカウント識別子を返す
  Future<CustomAuthInvalidationState> getInvalidationState() async {
    final entries = await getInvalidationEntries();
    if (entries.isEmpty) {
      return (isInvalidated: false, targetUserId: null, targetEmail: null);
    }
    final latest = entries.last;
    return (
      isInvalidated: true,
      targetUserId: latest.targetUserId,
      targetEmail: latest.targetEmail,
    );
  }

  static bool _matchesExactIdentifier({
    required Object? rowUserId,
    required Object? rowEmail,
    required String? targetUserId,
    required String? normalizedEmail,
  }) {
    return (rowUserId as String?) == targetUserId &&
        (rowEmail as String?) == normalizedEmail;
  }

  /// セッション無効化状態を削除対象アカウント情報とともに SQLite へ追加永続化し、発行した行 ID を返す
  ///
  /// 同一アカウントの並行退会や他アカウントの進行中レコードを上書き・共有しないよう、
  /// 呼び出しごとに独立したレコードを追加します。
  Future<int> markInvalidated({
    String? targetUserId,
    String? targetEmail,
  }) async {
    final dir = await _getDirectory();
    await dir.create(recursive: true);
    final dbFile = File(p.join(dir.path, databaseFileName));
    final normalizedEmail = _normalizeEmail(targetEmail);

    return await _runWithExecutor(dbFile, (executor) async {
      return await executor.runInsert(
        'INSERT INTO custom_auth_invalidation_entries '
        '(target_user_id, target_email) VALUES (?, ?);',
        [targetUserId, normalizedEmail],
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
    final entries = await getInvalidationEntries();
    if (entries.isEmpty) {
      return true;
    }

    if (isDeletionInProgress) {
      // 進行中の退会処理が所有している無効化レコードは別アカウントのログイン時でも削除しない
      return false;
    }

    final blockedBySameAccount = entries.any(
      (entry) => matchesAccount(
        targetUserId: entry.targetUserId,
        targetEmail: entry.targetEmail,
        candidateUserId: userId,
        candidateEmail: email,
        defaultWhenUnidentifiable: false,
      ),
    );
    if (blockedBySameAccount) {
      return false;
    }

    await clearInvalidated();
    return true;
  }

  /// 保存済みの無効化レコードのうち指定対象のみを削除し、他処理・他アカウントのレコードは保持する
  ///
  /// [entryId] が指定された場合は該当の 1 行のみを削除し、`null` の場合は
  /// 指定アカウント（[targetUserId] / [targetEmail]）に一致するすべての行を削除します。
  Future<void> clearInvalidatedIfMatches({
    required String? targetUserId,
    required String? targetEmail,
    int? entryId,
  }) async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return;
    }

    await _runWithExecutor(dbFile, (executor) async {
      if (entryId != null) {
        await executor.runDelete(
          'DELETE FROM custom_auth_invalidation_entries WHERE id = ?;',
          [entryId],
        );
        return;
      }

      final normalizedEmail = _normalizeEmail(targetEmail);
      final rows = await executor.runSelect(
        'SELECT id, target_user_id, target_email '
        'FROM custom_auth_invalidation_entries;',
        const [],
      );
      for (final row in rows) {
        if (_matchesExactIdentifier(
          rowUserId: row['target_user_id'],
          rowEmail: row['target_email'],
          targetUserId: targetUserId,
          normalizedEmail: normalizedEmail,
        )) {
          await executor.runDelete(
            'DELETE FROM custom_auth_invalidation_entries WHERE id = ?;',
            [row['id']],
          );
        }
      }
    });
  }

  /// SQLite 上のすべてのセッション無効化レコードを削除して確定保存する
  Future<void> clearInvalidated() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return;
    }

    await _runWithExecutor(dbFile, (executor) async {
      await executor.runDelete(
        'DELETE FROM custom_auth_invalidation_entries;',
        const [],
      );
    });
  }

  /// ログイン資格情報の保存が未確定のまま中断された状態が永続化されているかを返す
  Future<bool> isLoginPending() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return false;
    }

    return await _runWithExecutor(dbFile, (executor) async {
      final rows = await executor.runSelect(
        'SELECT pending FROM custom_auth_pending_login WHERE id = 1;',
        const [],
      );
      return rows.isNotEmpty && rows.first['pending'] == 1;
    });
  }

  /// ログイン資格情報の保存開始（未確定状態）を SQLite へ確定保存する
  Future<void> markLoginPending() async {
    final dir = await _getDirectory();
    await dir.create(recursive: true);
    final dbFile = File(p.join(dir.path, databaseFileName));

    await _runWithExecutor(dbFile, (executor) async {
      await executor.runInsert(
        'INSERT OR REPLACE INTO custom_auth_pending_login (id, pending) '
        'VALUES (1, 1);',
        const [],
      );
    });
  }

  /// ログイン資格情報の保存確定またはロールバック消去完了後に未確定状態を解除する
  Future<void> clearLoginPending() async {
    final dir = await _getDirectory();
    final dbFile = File(p.join(dir.path, databaseFileName));
    if (!dbFile.existsSync()) {
      return;
    }

    await _runWithExecutor(dbFile, (executor) async {
      await executor.runDelete(
        'DELETE FROM custom_auth_pending_login WHERE id = 1;',
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
