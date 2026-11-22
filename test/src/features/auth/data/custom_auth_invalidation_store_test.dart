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
        '再インスタンス化しても true を返すこと', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      await store.markInvalidated();

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

      // 別インスタンスで再読み込みしても永続化状態が維持されていること
      final restartedStore = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );
      check(await restartedStore.isInvalidated()).equals(true);
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
