import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lock_suppression_handler.g.dart';

/// 外部画面表示時（ブラウザ・カメラ・共有シート等）にアプリロックを一時停止しながら非同期処理を実行する関数の型定義
typedef LockSuppressionRunner =
    Future<T> Function<T>(Future<T> Function() action);

/// アプリロック一時停止ハンドラーを提供するプロバイダー
///
/// デフォルト実装は、Core層が特定機能に依存しないよう、処理をそのまま実行するNo-Op（透過的）関数を提供します。
/// アプリ起動時に `appLockOverrides` 等を通じて本実装がオーバーライドされます。
@Riverpod(keepAlive: true)
LockSuppressionRunner lockSuppressionRunner(Ref ref) {
  return <T>(action) => action();
}
