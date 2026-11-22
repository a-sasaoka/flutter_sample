import 'dart:io';

import 'package:checks/checks.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter_sample/src/features/auth/data/custom_auth_invalidation_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

class _TestQueryExecutorUser implements QueryExecutorUser {
  const _TestQueryExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

void main() {
  late Directory tempRoot;
  late Directory supportDir;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync(
      'custom_auth_invalidation_store_test_',
    );
    supportDir = Directory(p.join(tempRoot.path, 'nested', 'support'));
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      Process.runSync('chmod', ['-R', '755', tempRoot.path]);
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('CustomAuthInvalidationStore', () {
    test('初期状態では SQLite ファイルを作らず isInvalidated が false を返すこと', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      check(await store.isInvalidated()).equals(false);
      await store.clearInvalidated();

      final dbFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.databaseFileName),
      );
      check(dbFile.existsSync()).equals(false);
    });

    test('本番用 SQLite 接続に耐久 PRAGMA が設定され、markInvalidated 後に '
        '再インスタンス化しても true と識別子を返すこと', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: ' User@Example.com ',
      );

      final dbFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.databaseFileName),
      );
      check(dbFile.existsSync()).equals(true);

      // 本番用の接続設定メソッド自身を開いて PRAGMA 実測値を検証する
      final executor = CustomAuthInvalidationStore.createDurableDatabase(
        dbFile,
      );
      try {
        await executor.ensureOpen(const _TestQueryExecutorUser());
        final journalRows = await executor.runSelect(
          'PRAGMA journal_mode;',
          const [],
        );
        final syncRows = await executor.runSelect(
          'PRAGMA synchronous;',
          const [],
        );
        final fullFsyncRows = await executor.runSelect(
          'PRAGMA fullfsync;',
          const [],
        );
        final busyTimeoutRows = await executor.runSelect(
          'PRAGMA busy_timeout;',
          const [],
        );

        check(
          (journalRows.single.values.single! as String).toLowerCase(),
        ).equals('delete');
        check(syncRows.single.values.single).equals(3); // EXTRA
        check(fullFsyncRows.single.values.single).equals(1); // ON
        check(busyTimeoutRows.single.values.single).equals(5000);
      } finally {
        await executor.close();
      }

      // 別インスタンスで再読み込みしても永続化状態と正規化済み識別子が維持されていること
      final restartedStore = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );
      final state = await restartedStore.getInvalidationState();
      check(state.isInvalidated).equals(true);
      check(state.targetUserId).equals('user-a');
      check(state.targetEmail).equals('user@example.com');
    });

    test('対象列が無い旧スキーマ DB が残っていても自動的に列を追加して読み書きできること', () async {
      supportDir.createSync(recursive: true);
      final dbFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.databaseFileName),
      );
      final legacyExecutor = NativeDatabase(
        dbFile,
        enableMigrations: false,
        setup: (db) {
          db
            ..execute('''
              CREATE TABLE custom_auth_invalidation (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                invalidated INTEGER NOT NULL
              );
            ''')
            ..execute(
              'INSERT INTO custom_auth_invalidation (id, invalidated) '
              'VALUES (1, 1);',
            );
        },
      );
      try {
        await legacyExecutor.ensureOpen(const _TestQueryExecutorUser());
      } finally {
        await legacyExecutor.close();
      }

      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );
      final state = await store.getInvalidationState();
      check(state.isInvalidated).equals(true);
      check(state.targetUserId).isNull();
      check(state.targetEmail).isNull();
    });

    test('matchesAccount: userId 優先比較・email フォールバック・未識別時既定値が正しいこと', () {
      check(
        CustomAuthInvalidationStore.matchesAccount(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
          candidateUserId: 'user-a',
          candidateEmail: 'other@example.com',
          defaultWhenUnidentifiable: false,
        ),
      ).equals(true);

      // 同一メールアドレスでも userId が異なれば別アカウントとして扱うこと
      check(
        CustomAuthInvalidationStore.matchesAccount(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
          candidateUserId: 'user-b',
          candidateEmail: 'a@example.com',
          defaultWhenUnidentifiable: true,
        ),
      ).equals(false);

      // userId が欠落する場合は空白・大文字小文字を正規化した email で照合すること
      check(
        CustomAuthInvalidationStore.matchesAccount(
          targetUserId: null,
          targetEmail: ' User@Example.com ',
          candidateUserId: null,
          candidateEmail: 'user@example.com',
          defaultWhenUnidentifiable: false,
        ),
      ).equals(true);

      check(
        CustomAuthInvalidationStore.matchesAccount(
          targetUserId: null,
          targetEmail: ' ',
          candidateUserId: null,
          candidateEmail: null,
          defaultWhenUnidentifiable: true,
        ),
      ).equals(true);
      check(
        CustomAuthInvalidationStore.matchesAccount(
          targetUserId: null,
          targetEmail: null,
          candidateUserId: null,
          candidateEmail: null,
          defaultWhenUnidentifiable: false,
        ),
      ).equals(false);
    });

    test('clearIfAllowedForLogin: 退会進行中および同一アカウント時は保持し、 '
        '退会進行中でない別アカウント時は解除すること', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      // 未無効化時は即 true
      check(
        await store.clearIfAllowedForLogin(
          userId: 'user-a',
          email: 'a@example.com',
          isDeletionInProgress: false,
        ),
      ).equals(true);

      // 同一アカウントでは保持
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      check(
        await store.clearIfAllowedForLogin(
          userId: 'user-a',
          email: 'a@example.com',
          isDeletionInProgress: true,
        ),
      ).equals(false);
      check(await store.isInvalidated()).equals(true);

      // 別アカウントでも退会処理進行中なら退会側が所有するレコードは削除しない
      check(
        await store.clearIfAllowedForLogin(
          userId: 'user-b',
          email: 'b@example.com',
          isDeletionInProgress: true,
        ),
      ).equals(false);
      check(await store.isInvalidated()).equals(true);

      // 退会進行中でない状態なら別アカウントログインで解除される
      check(
        await store.clearIfAllowedForLogin(
          userId: 'user-b',
          email: 'b@example.com',
          isDeletionInProgress: false,
        ),
      ).equals(true);
      check(await store.isInvalidated()).equals(false);

      // 識別不能かつ削除進行中は保持、削除進行外なら解除
      await store.markInvalidated();
      check(
        await store.clearIfAllowedForLogin(
          userId: null,
          email: null,
          isDeletionInProgress: true,
        ),
      ).equals(false);
      check(await store.isInvalidated()).equals(true);

      check(
        await store.clearIfAllowedForLogin(
          userId: null,
          email: null,
          isDeletionInProgress: false,
        ),
      ).equals(true);
      check(await store.isInvalidated()).equals(false);
    });

    test('clearInvalidatedIfMatches: 対象アカウントが一致する場合のみレコードを解除すること', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      // 未無効化時は何もしない
      await store.clearInvalidatedIfMatches(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      check(await store.isInvalidated()).equals(false);

      // 別アカウント所有のレコードは解除しない
      await store.markInvalidated(
        targetUserId: 'user-b',
        targetEmail: 'b@example.com',
      );
      await store.clearInvalidatedIfMatches(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final afterMismatch = await store.getInvalidationState();
      check(afterMismatch.isInvalidated).equals(true);
      check(afterMismatch.targetUserId).equals('user-b');

      // 一致するレコードは解除する
      await store.clearInvalidatedIfMatches(
        targetUserId: 'user-b',
        targetEmail: ' B@EXAMPLE.COM ',
      );
      check(await store.isInvalidated()).equals(false);
    });

    test('clearInvalidated は無効化レコードを削除し、再インスタンス化後も false を返すこと', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      await store.markInvalidated();
      check(await store.isInvalidated()).equals(true);

      await store.clearInvalidated();
      check(await store.isInvalidated()).equals(false);

      final restartedStore = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );
      check(await restartedStore.isInvalidated()).equals(false);
    });

    test('DB パスが書き込み不可で SQLite 書き込みに失敗した場合は SqliteException を送出すること', () async {
      Directory(
        p.join(supportDir.path, CustomAuthInvalidationStore.databaseFileName),
      ).createSync(recursive: true);

      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      await check(store.markInvalidated()).throws<SqliteException>();
    });

    test('customAuthInvalidationStoreProvider がディレクトリリーダ経由で永続化できること', () async {
      final container = ProviderContainer(
        overrides: [
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => supportDir,
          ),
        ],
      );
      addTearDown(container.dispose);

      final store = container.read(customAuthInvalidationStoreProvider);
      await store.markInvalidated();
      check(await store.isInvalidated()).equals(true);

      await store.clearInvalidated();
      check(await store.isInvalidated()).equals(false);
    });
  });
}
