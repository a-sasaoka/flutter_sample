import 'dart:io';

import 'package:checks/checks.dart';
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
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('CustomAuthInvalidationStore', () {
    test('初期状態では無効化マーカーが存在せず isInvalidated が false を返すこと', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      check(await store.isInvalidated()).equals(false);
    });

    test('markInvalidated は一時ファイルへのフラッシュとアトミックリネームで '
        'ディスクへ永続化し、再インスタンス化後も true を返すこと', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      await store.markInvalidated();

      final markerFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.markerFileName),
      );
      final tempFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.tempFileName),
      );
      check(markerFile.existsSync()).equals(true);
      check(markerFile.readAsStringSync()).equals('invalidated');
      check(tempFile.existsSync()).equals(false);

      // アプリ再起動に相当する別インスタンスでも同一ディスク状態を検知できること
      final restartedStore = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );
      check(await restartedStore.isInvalidated()).equals(true);
    });

    test('clearInvalidated はマーカーと残留一時ファイルを削除し、未存在時もエラーなく完了すること', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      // 未存在状態でのクリアが安全に完了すること
      await store.clearInvalidated();
      check(await store.isInvalidated()).equals(false);

      // マーカーと残留一時ファイルを配置したうえで削除できること
      await store.markInvalidated();
      final tempFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.tempFileName),
      )..writeAsStringSync('leftover', flush: true);
      check(tempFile.existsSync()).equals(true);

      await store.clearInvalidated();

      final markerFile = File(
        p.join(supportDir.path, CustomAuthInvalidationStore.markerFileName),
      );
      check(markerFile.existsSync()).equals(false);
      check(tempFile.existsSync()).equals(false);
      check(await store.isInvalidated()).equals(false);
    });

    test('一時ファイル書き込みに失敗した場合は例外を投げ、マーカーを作成しないこと', () async {
      final blockingDir = Directory(
        p.join(supportDir.path, CustomAuthInvalidationStore.tempFileName),
      )..createSync(recursive: true);
      check(blockingDir.existsSync()).equals(true);

      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );

      await check(store.markInvalidated()).throws<FileSystemException>();
      check(await store.isInvalidated()).equals(false);
    });

    test('customAuthInvalidationStoreProvider がディレクトリリーダを使って動作すること', () async {
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
    });
  });
}
