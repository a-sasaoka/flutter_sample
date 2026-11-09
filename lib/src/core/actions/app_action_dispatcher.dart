import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_action_dispatcher.g.dart';

/// アプリ機能（ツール）の実行を受け付ける共通ディスパッチャーのインターフェース
abstract class AppActionDispatcher {
  /// ツール名と引数を渡してアプリ操作を実行する
  Future<Map<String, Object?>> execute({
    required String name,
    required Map<String, Object?> args,
  });
}

/// 共通ディスパッチャーを提供するプロバイダー
///
/// Core層が個別Featureに依存しないよう、デフォルトは未設定（UnimplementedError）とし、
/// アプリ起動時（`main.dart`）やテスト時に具体的な実装でオーバーライドされます。
@Riverpod(keepAlive: true)
AppActionDispatcher appActionDispatcher(Ref ref) {
  throw UnimplementedError('appActionDispatcherProvider must be overridden');
}
