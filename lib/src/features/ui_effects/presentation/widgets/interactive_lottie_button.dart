import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/ui_effects/presentation/controllers/submit_animation_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

/// 送信状態と連動してアニメーションが切り替わるインタラクティブなLottieボタン
class InteractiveLottieButton extends HookConsumerWidget {
  /// コンストラクタ
  const InteractiveLottieButton({
    required this.assetPath,
    required this.onComplete,
    this.buttonText,
    this.animate = true,
    super.key,
  });

  /// アニメーションJSONファイルのアセットパス
  final String assetPath;

  /// アニメーション完了時に呼ばれるコールバック
  final VoidCallback onComplete;

  /// 待機時にボタンに表示するテキスト（未指定時は多言語化デフォルト）
  final String? buttonText;

  /// アニメーションを再生するかどうか（テスト用）
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // フックを使ってAnimationControllerを安全に生成＆自動dispose
    final animationController = useAnimationController();

    // このボタン自身が送信処理を開始したかを追跡するボタン単位のローカル状態
    final isSubmitting = useState(false);

    // 状態の変化（副作用）を検知してアニメーションを制御する
    ref.listen<SubmitStatus>(submitAnimationControllerProvider, (
      previous,
      next,
    ) {
      if (next == SubmitStatus.loading) {
        if (animate) {
          // ローディング区間（0.0〜0.5）をループ再生
          animationController.repeat(
            max: 0.5,
            period: const Duration(milliseconds: 1200),
          );
        }
      } else if (next == SubmitStatus.success) {
        // このボタン自身が送信元である場合のみ onComplete を呼び出す
        if (isSubmitting.value) {
          isSubmitting.value = false;
          if (animate) {
            // 成功区間（0.5〜1.0）へ再生してチェックマークを弾けさせる
            animationController.stop();
            unawaited(
              animationController
                  .animateTo(
                    1,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                  )
                  .then((_) {
                    onComplete();
                  }),
            );
          } else {
            onComplete();
          }
        }
      } else if (next == SubmitStatus.idle) {
        isSubmitting.value = false;
        animationController.reset();
      } else if (next == SubmitStatus.error) {
        isSubmitting.value = false;
      }
    });

    final currentStatus = ref.watch(submitAnimationControllerProvider);

    return SizedBox(
      width: 240,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed:
            currentStatus == SubmitStatus.idle ||
                currentStatus == SubmitStatus.error
            ? () {
                isSubmitting.value = true;
                unawaited(
                  ref.read(submitAnimationControllerProvider.notifier).submit(),
                );
              }
            : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child:
              currentStatus == SubmitStatus.idle ||
                  currentStatus == SubmitStatus.error
              ? Row(
                  key: const ValueKey('idle_content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentStatus == SubmitStatus.error
                          ? Icons.refresh_rounded
                          : Icons.send_rounded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentStatus == SubmitStatus.error
                          ? l10n.uiEffectsRetryButton
                          : (buttonText ?? l10n.uiEffectsSubmitButton),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : Lottie.asset(
                  assetPath,
                  key: const ValueKey('lottie_content'),
                  controller: animationController,
                  onLoaded: (composition) {
                    animationController.duration = composition.duration;
                  },
                ),
        ),
      ),
    );
  }
}
