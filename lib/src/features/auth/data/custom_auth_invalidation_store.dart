import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_auth_invalidation_store.g.dart';

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

/// カスタム認証の退会に伴うセッション無効化状態をディスク上に永続化するストア
///
/// 書き込み完了時のフラッシュ（`flush: true`）と一時ファイルからのアトミックな
/// リネームにより、`SharedPreferences` と異なり完了時点でディスク永続化を保証します。
class CustomAuthInvalidationStore {
  /// [CustomAuthInvalidationStore] を生成する
  CustomAuthInvalidationStore({
    required Future<Directory> Function() getDirectory,
  }) : _getDirectory = getDirectory;

  final Future<Directory> Function() _getDirectory;

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

  /// セッション無効化状態をディスクへフラッシュ書き込みし、アトミックに確定する
  Future<void> markInvalidated() async {
    final dir = await _getDirectory();
    await dir.create(recursive: true);
    final tempFile = File(p.join(dir.path, tempFileName));
    final markerFile = File(p.join(dir.path, markerFileName));
    await tempFile.writeAsString('invalidated', flush: true);
    await tempFile.rename(markerFile.path);
  }

  /// ディスク上のセッション無効化マーカーと残留一時ファイルを削除する
  Future<void> clearInvalidated() async {
    final dir = await _getDirectory();
    final markerFile = File(p.join(dir.path, markerFileName));
    if (markerFile.existsSync()) {
      await markerFile.delete();
    }
    final tempFile = File(p.join(dir.path, tempFileName));
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
  }
}
