import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/utils/scaffold_messenger_key.dart';

/// 🚀 画面遷移（Push/Pop）を検知して、表示中のスナックバーを自動で消去するオブザーバー。
class SnackBarNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 新しい画面へ遷移した時に、現在表示中のスナックバーをすべて消去する
    scaffoldMessengerKey.currentState?.clearSnackBars();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // 前の画面に戻った時に、現在表示中のスナックバーをすべて消去する
    scaffoldMessengerKey.currentState?.clearSnackBars();
  }
}
