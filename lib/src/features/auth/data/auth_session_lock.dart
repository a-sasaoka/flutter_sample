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
  int _sessionEpoch = 0;

  /// 現在の認証セッション世代（ログイン・ログアウト時に更新される）
  int get sessionEpoch => _sessionEpoch;

  /// ロックを取得し、[action] の完了まで後続のセッション操作を待機させる
  Future<T> synchronized<T>(Future<T> Function() action) {
    // 先行処理の成否にかかわらず順番を守って実行し、返却Futureへはactionの結果のみを伝える
    final current = _tail.then((_) => action());
    _tail = current.then<void>((_) {}, onError: (Object _) {});
    return current;
  }

  /// ロックを取得してセッション世代を進めた上で、ログインやログアウト等の [action] を実行する
  Future<T> runSessionTransition<T>(Future<T> Function() action) {
    return synchronized(() {
      _sessionEpoch++;
      return action();
    });
  }

  /// 現在の世代が [expectedEpoch] と一致する場合のみセッション世代を進めて [action] を実行する
  Future<bool> runSessionTransitionIfCurrent({
    required int expectedEpoch,
    required Future<void> Function() action,
  }) {
    return synchronized(() async {
      if (_sessionEpoch != expectedEpoch) {
        return false;
      }
      _sessionEpoch++;
      await action();
      return true;
    });
  }
}
