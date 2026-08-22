import 'package:flutter/material.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';

/// 📭 データが0件の時やエラー時に表示する汎用空状態 Widget
class EmptyStateWidget extends StatelessWidget {
  /// コンストラクタ
  const EmptyStateWidget({
    required this.title,
    super.key,
    this.lottie,
    this.description,
    this.actionLabel,
    this.onAction,
    this.animate,
    this.lottieSize = 180,
  });

  /// 表示する Lottie アニメーション（指定がない場合は emptyBox を使用）
  final LottieGenImage? lottie;

  /// タイトルテキスト
  final String title;

  /// 説明テキスト（省略可）
  final String? description;

  /// アクションボタンのラベル（省略可）
  final String? actionLabel;

  /// アクションボタンタップ時の処理（省略可）
  final VoidCallback? onAction;

  /// アニメーション再生フラグ（未指定時は実機で自動再生、テスト環境で自動静止画）
  final bool? animate;

  /// アニメーションのサイズ（幅・高さ）
  final double lottieSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lottieAsset = lottie ?? Assets.animations.emptyBox;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLottieWidget.asset(
              lottie: lottieAsset,
              width: lottieSize,
              height: lottieSize,
              animate: animate,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description case final String desc) ...[
              const SizedBox(height: 8),
              Text(
                desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel case final String label) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
