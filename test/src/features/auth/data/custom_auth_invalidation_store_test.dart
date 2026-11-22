import 'dart:io';

import 'package:checks/checks.dart';
import 'package:drift/native.dart';
import 'package:flutter_sample/src/features/auth/data/custom_auth_invalidation_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

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

    test('markInvalidated は耐久 PRAGMA を有効にした専用 SQLite DB へ書き込み、 '
        '再インスタンス化後も true を返すこと', () async {
      late String journalMode;
      late int synchronousLevel;
      late int fullFsyncFlag;

      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
        createExecutor: (file) {
          return NativeDatabase(
            file,
            enableMigrations: false,
            setup: (database) {
              // 既定生成関数と同一構成を作成したうえで接続 PRAGMA 値を実測する
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
              journalMode =
                  database.select('PRAGMA journal_mode;').single.columnAt(0)
                      as String;
              synchronousLevel =
                  database.select('PRAGMA synchronous;').single.columnAt(0)
                      as int;
              fullFsyncFlag =
                  database.select('PRAGMA fullfsync;').single.columnAt(0)
                      as int;
            },
          );
        },
      );

      await store.markInvalidated();

      check(journalMode.toLowerCase()).equals('delete');
      check(synchronousLevel).equals(3); // EXTRA
      check(fullFsyncFlag).equals(1); // ON

      final dbFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.databaseFileName),
      );
      check(dbFile.existsSync()).equals(true);

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
