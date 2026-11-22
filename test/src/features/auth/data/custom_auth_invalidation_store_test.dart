import 'dart:ffi';
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

    test('markInvalidated は一時ファイルへのフラッシュ・アトミックリネーム・親ディレクトリ同期を行い、 '
        '再インスタンス化後も true を返すこと', () async {
      final nativeSync = PosixDirectorySyncBindings.native().syncDirectory;
      final syncedPaths = <String>[];
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
        syncDirectory: (dir) async {
          syncedPaths.add(dir.path);
          await nativeSync(dir);
        },
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
      check(syncedPaths).deepEquals([supportDir.path]);

      // アプリ再起動に相当する別インスタンスでも同一ディスク状態を検知できること
      final restartedStore = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
      );
      check(await restartedStore.isInvalidated()).equals(true);
    });

    test('clearInvalidated はマーカーと残留一時ファイルを削除して親ディレクトリを同期し、 '
        '未存在時は同期せず完了すること', () async {
      final nativeSync = PosixDirectorySyncBindings.native().syncDirectory;
      final syncedPaths = <String>[];
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
        syncDirectory: (dir) async {
          syncedPaths.add(dir.path);
          await nativeSync(dir);
        },
      );

      // 未存在状態でのクリアは安全に完了し、不要なディレクトリ同期を行わないこと
      await store.clearInvalidated();
      check(await store.isInvalidated()).equals(false);
      check(syncedPaths).isEmpty();

      // マーカーと残留一時ファイルを配置したうえで削除・同期できること
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
      check(syncedPaths).deepEquals([supportDir.path, supportDir.path]);
    });

    test('一時ファイル書き込みに失敗した場合は例外を投げ、マーカーを作成しないこと', () async {
      final blockingDir = Directory(
        p.join(supportDir.path, CustomAuthInvalidationStore.tempFileName),
      )..createSync(recursive: true);
      check(blockingDir.existsSync()).equals(true);

      var syncCalled = false;
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
        syncDirectory: (_) async {
          syncCalled = true;
        },
      );

      await check(store.markInvalidated()).throws<FileSystemException>();
      check(await store.isInvalidated()).equals(false);
      check(syncCalled).equals(false);
    });

    test('親ディレクトリの同期に失敗した場合も FileSystemException を送出すること', () async {
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => supportDir,
        syncDirectory: (dir) async {
          throw FileSystemException('sync failed', dir.path);
        },
      );

      await check(store.markInvalidated()).throws<FileSystemException>();
    });

    test(
      'customAuthInvalidationStoreProvider がディレクトリリーダと同期プロバイダで動作すること',
      () async {
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
      },
    );
  });

  group('PosixDirectorySyncBindings', () {
    test('Apple環境では F_FULLFSYNC を優先実行し、成功時は fsync を呼ばず fd を閉じること', () async {
      supportDir.createSync(recursive: true);
      final native = PosixDirectorySyncBindings.native();
      final calls = <String>[];
      final bindings = PosixDirectorySyncBindings(
        allocateBytes: native.allocateBytes,
        freeBytes: native.freeBytes,
        openPath: (path, oflag) {
          calls.add('open:$oflag');
          return 42;
        },
        fcntlFd: (fd, cmd) {
          calls.add('fcntl:$fd:$cmd');
          return 0;
        },
        fsyncFd: (fd) {
          calls.add('fsync:$fd');
          return 0;
        },
        closeFd: (fd) {
          calls.add('close:$fd');
          return 0;
        },
        isApplePlatform: () => true,
      );

      await bindings.syncDirectory(supportDir);
      check(calls).deepEquals(['open:0', 'fcntl:42:51', 'close:42']);
    });

    test('Apple環境で F_FULLFSYNC が失敗した場合は fsync へフォールバックせず '
        'fd を閉じて例外を投げること', () async {
      supportDir.createSync(recursive: true);
      final native = PosixDirectorySyncBindings.native();
      final calls = <String>[];
      final bindings = PosixDirectorySyncBindings(
        allocateBytes: native.allocateBytes,
        freeBytes: native.freeBytes,
        openPath: (_, _) => 7,
        fcntlFd: (fd, cmd) {
          calls.add('fcntl:$fd:$cmd');
          return -1;
        },
        fsyncFd: (fd) {
          calls.add('fsync:$fd');
          return 0;
        },
        closeFd: (fd) {
          calls.add('close:$fd');
          return 0;
        },
        isApplePlatform: () => true,
      );

      await check(
        bindings.syncDirectory(supportDir),
      ).throws<FileSystemException>();
      check(calls).deepEquals(['fcntl:7:51', 'close:7']);
    });

    test('Android / Linux 環境では fsync を直接実行し、失敗時は fd を閉じて例外を投げること', () async {
      supportDir.createSync(recursive: true);
      final native = PosixDirectorySyncBindings.native();
      final calls = <String>[];
      var fsyncResult = 0;
      final bindings = PosixDirectorySyncBindings(
        allocateBytes: native.allocateBytes,
        freeBytes: native.freeBytes,
        openPath: (_, _) => 9,
        fcntlFd: (fd, cmd) {
          calls.add('fcntl:$fd:$cmd');
          return 0;
        },
        fsyncFd: (fd) {
          calls.add('fsync:$fd');
          return fsyncResult;
        },
        closeFd: (fd) {
          calls.add('close:$fd');
          return 0;
        },
        isApplePlatform: () => false,
      );

      await bindings.syncDirectory(supportDir);
      check(calls).deepEquals(['fsync:9', 'close:9']);

      calls.clear();
      fsyncResult = -1;
      await check(
        bindings.syncDirectory(supportDir),
      ).throws<FileSystemException>();
      check(calls).deepEquals(['fsync:9', 'close:9']);
    });

    test('open 失敗時・メモリ確保失敗時は FileSystemException を送りリソース解放すること', () async {
      supportDir.createSync(recursive: true);
      final native = PosixDirectorySyncBindings.native();
      var freeCalls = 0;
      var closeCalled = false;

      final openFailBindings = PosixDirectorySyncBindings(
        allocateBytes: native.allocateBytes,
        freeBytes: (ptr) {
          freeCalls++;
          native.freeBytes(ptr);
        },
        openPath: (_, _) => -1,
        fcntlFd: (_, _) => 0,
        fsyncFd: (_) => 0,
        closeFd: (_) {
          closeCalled = true;
          return 0;
        },
        isApplePlatform: () => false,
      );

      await check(
        openFailBindings.syncDirectory(supportDir),
      ).throws<FileSystemException>();
      check(freeCalls).equals(1);
      check(closeCalled).equals(false);

      final allocFailBindings = PosixDirectorySyncBindings(
        allocateBytes: (_) => nullptr,
        freeBytes: native.freeBytes,
        openPath: (_, _) => 1,
        fcntlFd: (_, _) => 0,
        fsyncFd: (_) => 0,
        closeFd: (_) => 0,
        isApplePlatform: () => false,
      );

      await check(
        allocFailBindings.syncDirectory(supportDir),
      ).throws<FileSystemException>();
    });
  });
}
