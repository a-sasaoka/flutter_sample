import 'package:flutter/material.dart';

/// 🚀 画面遷移（Push/Pop/Replace）を検知して、表示中のスナックバーを自動で消去するオブザーバー。
class SnackBarNavigationObserver extends NavigatorObserver {
  /// [ScaffoldMessengerState] にアクセスするためのキーをコンストラクタで受け取る。
  SnackBarNavigationObserver(this._messengerKey);

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _clearSnackBars(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _clearSnackBars(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _clearSnackBars(newRoute);
    }
  }

  /// 画面（PageRoute）の遷移時のみ、表示中のスナックバーを消去する。
  /// ダイアログやボトムシート（PopupRoute）の開閉時は消去しない。
  void _clearSnackBars(Route<dynamic> route) {
    if (route is PageRoute) {
      _messengerKey.currentState?.clearSnackBars();
    }
  }
}
