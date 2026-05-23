import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_state_provider.g.dart';

/// 🌊 スプラッシュ画面の表示完了状態を管理するNotifierプロバイダー
///
/// アプリ起動時に最低表示時間（例：2秒）を満たしたかどうかを管理します。
@Riverpod(keepAlive: true)
class SplashState extends _$SplashState {
  @override
  bool build() {
    // 初期状態は「スプラッシュ画面表示中 (false)」
    return false;
  }

  /// スプラッシュ表示が完了したことを通知し、状態を true (完了) に更新します。
  void finishSplash() {
    state = true;
  }
}
