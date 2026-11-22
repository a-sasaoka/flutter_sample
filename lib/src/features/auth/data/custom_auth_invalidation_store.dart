import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_auth_invalidation_store.g.dart';

typedef _MallocNative = Pointer<Uint8> Function(IntPtr size);
typedef _MallocDart = Pointer<Uint8> Function(int size);
typedef _FreeNative = Void Function(Pointer<Uint8> ptr);
typedef _FreeDart = void Function(Pointer<Uint8> ptr);
typedef _OpenNative = Int Function(Pointer<Uint8> path, Int oflag, VarArgs<()>);
typedef _OpenDart = int Function(Pointer<Uint8> path, int oflag);
typedef _FsyncNative = Int Function(Int fd);
typedef _FsyncDart = int Function(int fd);
typedef _FcntlNative = Int Function(Int fd, Int cmd, VarArgs<()>);
typedef _FcntlDart = int Function(int fd, int cmd);
typedef _CloseNative = Int Function(Int fd);
typedef _CloseDart = int Function(int fd);

/// ディレクトリエントリの変更をディスクへ同期する関数型
typedef DirectorySyncer = Future<void> Function(Directory directory);

/// POSIX システムコール経由でディレクトリをディスクへ同期するバインディング
@visibleForTesting
class PosixDirectorySyncBindings {
  /// 指定したシステムコール関数を用いて [PosixDirectorySyncBindings] を生成する
  const PosixDirectorySyncBindings({
    required this.allocateBytes,
    required this.freeBytes,
    required this.openPath,
    required this.fsyncFd,
    required this.fcntlFd,
    required this.closeFd,
    required this.isApplePlatform,
  });

  /// 実行環境の libc からネイティブバインディングを生成する
  factory PosixDirectorySyncBindings.native() {
    final libc = _openLibc();
    return PosixDirectorySyncBindings(
      allocateBytes: libc.lookupFunction<_MallocNative, _MallocDart>('malloc'),
      freeBytes: libc.lookupFunction<_FreeNative, _FreeDart>('free'),
      openPath: libc.lookupFunction<_OpenNative, _OpenDart>('open'),
      fsyncFd: libc.lookupFunction<_FsyncNative, _FsyncDart>('fsync'),
      fcntlFd: libc.lookupFunction<_FcntlNative, _FcntlDart>('fcntl'),
      closeFd: libc.lookupFunction<_CloseNative, _CloseDart>('close'),
      isApplePlatform: () => Platform.isIOS || Platform.isMacOS,
    );
  }

  /// 一時バッファ確保関数 (`malloc`)
  final Pointer<Uint8> Function(int size) allocateBytes;

  /// 一時バッファ解放関数 (`free`)
  final void Function(Pointer<Uint8> ptr) freeBytes;

  /// パスをファイル記述子として開く関数 (`open`)
  final int Function(Pointer<Uint8> path, int oflag) openPath;

  /// ファイル記述子をディスクへ同期する関数 (`fsync`)
  final int Function(int fd) fsyncFd;

  /// macOS / iOS 向け制御システムコール関数 (`fcntl`)
  final int Function(int fd, int cmd) fcntlFd;

  /// ファイル記述子を閉じる関数 (`close`)
  final int Function(int fd) closeFd;

  /// Apple プラットフォーム（iOS / macOS）かを返す判定関数
  final bool Function() isApplePlatform;

  static DynamicLibrary _openLibc() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libc.so'); // coverage:ignore-line
    }
    return DynamicLibrary.process();
  }

  /// 対象ディレクトリのディレクトリエントリをディスクへ永続化する
  ///
  /// iOS / macOS では `F_FULLFSYNC`（未対応時のみ `fsync` へフォールバック）を実行し、
  /// Android / Linux では `fsync` を実行します。失敗時は [FileSystemException] を送出します。
  Future<void> syncDirectory(Directory directory) async {
    final encodedPath = utf8.encode(directory.path);
    final pathPtr = allocateBytes(encodedPath.length + 1);
    if (pathPtr == nullptr) {
      throw FileSystemException(
        'Failed to allocate memory for directory sync',
        directory.path,
      );
    }

    var fd = -1;
    try {
      pathPtr.asTypedList(encodedPath.length + 1)
        ..setAll(0, encodedPath)
        ..[encodedPath.length] = 0;

      const oRdonly = 0;
      fd = openPath(pathPtr, oRdonly);
      if (fd < 0) {
        throw FileSystemException(
          'Failed to open directory for disk sync',
          directory.path,
        );
      }

      if (isApplePlatform()) {
        const fFullfsync = 51;
        if (fcntlFd(fd, fFullfsync) == 0) {
          return;
        }
      }

      if (fsyncFd(fd) != 0) {
        throw FileSystemException(
          'Failed to synchronize directory entries to disk',
          directory.path,
        );
      }
    } finally {
      if (fd >= 0) {
        closeFd(fd);
      }
      freeBytes(pathPtr);
    }
  }
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

/// 親ディレクトリをディスクへ同期する関数を提供するプロバイダ
@Riverpod(keepAlive: true)
DirectorySyncer directorySyncer(Ref ref) {
  return PosixDirectorySyncBindings.native().syncDirectory;
}

/// [CustomAuthInvalidationStore] のプロバイダ
@Riverpod(keepAlive: true)
CustomAuthInvalidationStore customAuthInvalidationStore(Ref ref) {
  return CustomAuthInvalidationStore(
    getDirectory: ref.watch(appSupportDirectoryReaderProvider),
    syncDirectory: ref.watch(directorySyncerProvider),
  );
}

/// カスタム認証の退会に伴うセッション無効化状態をディスク上に永続化するストア
///
/// 一時ファイルへのフラッシュ書き込み（`flush: true`）・アトミックリネームに加え、
/// 親ディレクトリの同期（Android は `fsync`、iOS は `F_FULLFSYNC`）まで実行することで
/// 完了時点でのディスク永続化を保証します。
class CustomAuthInvalidationStore {
  /// [CustomAuthInvalidationStore] を生成する
  CustomAuthInvalidationStore({
    required Future<Directory> Function() getDirectory,
    DirectorySyncer? syncDirectory,
  }) : _getDirectory = getDirectory,
       _syncDirectory =
           syncDirectory ?? PosixDirectorySyncBindings.native().syncDirectory;

  final Future<Directory> Function() _getDirectory;
  final DirectorySyncer _syncDirectory;

  /// 永続化されたセッション無効化マーカーファイル名
  @visibleForTesting
  static const markerFileName = 'custom_auth_session_invalidated.flag';

  /// アトミック書き込み用の一時ファイル名
  @visibleForTesting
  static const tempFileName = 'custom_auth_session_invalidated.flag.tmp';

  /// セッション無効化状態がディスクに永続化されているかを返す
  Future<bool> isInvalidated() async {
    final dir = await _getDirectory();
    final markerFile = File(p.join(dir.path, markerFileName));
    return markerFile.existsSync();
  }

  /// セッション無効化状態をディスクへフラッシュ書き込みし、親ディレクトリを含めて確定する
  Future<void> markInvalidated() async {
    final dir = await _getDirectory();
    await dir.create(recursive: true);
    final tempFile = File(p.join(dir.path, tempFileName));
    final markerFile = File(p.join(dir.path, markerFileName));
    await tempFile.writeAsString('invalidated', flush: true);
    await tempFile.rename(markerFile.path);
    await _syncDirectory(dir);
  }

  /// ディスク上のセッション無効化マーカーと残留一時ファイルを削除する
  Future<void> clearInvalidated() async {
    final dir = await _getDirectory();
    var deleted = false;
    final markerFile = File(p.join(dir.path, markerFileName));
    if (markerFile.existsSync()) {
      await markerFile.delete();
      deleted = true;
    }
    final tempFile = File(p.join(dir.path, tempFileName));
    if (tempFile.existsSync()) {
      await tempFile.delete();
      deleted = true;
    }
    if (deleted) {
      await _syncDirectory(dir);
    }
  }
}
