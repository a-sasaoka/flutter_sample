import 'package:firebase_messaging/firebase_messaging.dart';

/// 🔔 アプリ終了時・バックグラウンド受信時のトップレベルメッセージハンドラ
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンドでメッセージを受信した際の処理
  // 注意: この関数は独立した Isolate で実行されるため、UI操作や Riverpod の参照は行わない
}
