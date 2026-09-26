import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_animation_controller.g.dart';

/// 送信処理のフェーズを表す列挙型
enum SubmitStatus {
  /// 待機中（通常のボタン表示）
  idle,

  /// 送信中（くるくるローディング）
  loading,

  /// 成功（チェックマークアニメーション）
  success,

  /// 失敗
  error,
}

/// 送信ボタンのアニメーション状態を管理するNotifier
@riverpod
class SubmitAnimationController extends _$SubmitAnimationController {
  @override
  SubmitStatus build() {
    return SubmitStatus.idle;
  }

  /// 送信処理を実行する
  Future<void> submit({
    Duration duration = const Duration(seconds: 2),
    bool isSuccess = true,
    Future<void> Function()? task,
  }) async {
    // 待機中(idle)およびエラー(error)以外（loadingやsuccess実行中）は多重タップをガード
    if (state != SubmitStatus.idle && state != SubmitStatus.error) {
      return;
    }

    state = SubmitStatus.loading;

    try {
      if (task != null) {
        await task();
      } else {
        // 擬似的な通信遅延（実際はAPI通信など）
        await Future<void>.delayed(duration);
      }

      // 非同期処理待機中にプロバイダーが破棄された場合は状態更新をスキップ
      if (!ref.mounted) {
        return;
      }

      if (!isSuccess) {
        state = SubmitStatus.error;
        return;
      }

      // 成功状態へ遷移
      state = SubmitStatus.success;
    } on Exception {
      if (ref.mounted) {
        state = SubmitStatus.error;
      }
    }
  }

  /// 状態を初期状態へリセットする
  void reset() {
    state = SubmitStatus.idle;
  }
}
