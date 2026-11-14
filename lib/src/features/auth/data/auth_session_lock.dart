import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_lock.g.dart';

/// 認証セッションの読み書きを直列化するロックを提供するプロバイダ
@Riverpod(keepAlive: true)
AuthSessionLock authSessionLock(Ref ref) {
  return AuthSessionLock();
}

/// トークンの確認・保存・削除を直列化して競合を防ぐ非同期ロック
class AuthSessionLock {
  Future<void> _tail = Future<void>.value();

  /// ロックを取得し、[action] の完了まで後続のセッション操作を待機させる
  Future<T> synchronized<T>(Future<T> Function() action) {
    // 先行処理の成否にかかわらず順番を守って実行し、返却Futureへはactionの結果のみを伝える
    final current = _tail.then((_) => action());
    _tail = current.then<void>((_) {}, onError: (Object _) {});
    return current;
  }
}
