import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';

/// 🎨 Lottie アニメーションの操作・デモ画面
///
/// 再生・一時停止・逆再生・停止・進捗シークバー・ループ設定・ネットワーク読み込みなど、
/// Lottie アニメーションの多彩な制御方法を実践的に学べるデモ画面です。
class LottieDemoScreen extends HookWidget {
  /// コンストラクタ
  const LottieDemoScreen({
    super.key,
    this.animate = true,
  });

  /// アニメーションを自動再生するかどうか（テスト時は false にしてタイムアウトを防止）
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // 1. アニメーションコントローラーの初期化（flutter_hooks を使用）
    final controller = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    // 2. 現在の進捗率（0.0 〜 1.0）とループ再生フラグの状態管理
    final progress = useState<double>(0);
    final isLoop = useState(true);
    final selectedIndex = useState(0);

    // 3. 表示可能なアセット一覧の定義
    final assetList = [
      (
        name: l10n.devLottieAssetOnboardingMemo,
        lottie: Assets.animations.onboardingMemo,
      ),
      (
        name: l10n.devLottieAssetOnboardingSync,
        lottie: Assets.animations.onboardingSync,
      ),
      (
        name: l10n.devLottieAssetOnboardingChat,
        lottie: Assets.animations.onboardingChat,
      ),
      (
        name: l10n.devLottieAssetEmptyBox,
        lottie: Assets.animations.emptyBox,
      ),
      (
        name: l10n.devLottieAssetNotFound,
        lottie: Assets.animations.notFound404,
      ),
      (
        name: l10n.devLottieAssetSuccessCheck,
        lottie: Assets.animations.successCheck,
      ),
    ];

    // 4. 初回マウント時の自動再生制御
    useEffect(
      () {
        if (animate) {
          unawaited(controller.forward());
        }
        return null;
      },
      [controller, animate],
    );

    // 5. アニメーションの進捗・完了を監視するリスナー
    useEffect(
      () {
        void listener() {
          progress.value = controller.value;
        }

        void statusListener(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            if (isLoop.value) {
              unawaited(controller.forward(from: 0));
            } else {
              context.showSnackBar(
                l10n.devLottieCompleted,
                duration: const Duration(seconds: 1),
              );
            }
          }
        }

        controller
          ..addListener(listener)
          ..addStatusListener(statusListener);

        return () {
          controller
            ..removeListener(listener)
            ..removeStatusListener(statusListener);
        };
      },
      [controller, isLoop.value],
    );

    final selectedAsset = assetList[selectedIndex.value];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devLottieTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // アニメーション表示カード
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 240,
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: AppLottieWidget.asset(
                lottie: selectedAsset.lottie,
                controller: controller,
                width: 200,
                height: 200,
                onLoaded: (composition) {
                  controller.duration = composition.duration;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // コントロールパネルカード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 進捗表示 ＆ シークバースライダー
                  Text(
                    l10n.devLottieProgress((progress.value * 100).toInt()),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: progress.value.clamp(0.0, 1.0),
                    onChanged: (value) {
                      controller.value = value;
                    },
                  ),
                  const SizedBox(height: 8),

                  // 再生・一時停止・逆再生・停止ボタン群
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 再生ボタン
                      IconButton.filledTonal(
                        onPressed: () => unawaited(controller.forward()),
                        icon: const Icon(Icons.play_arrow),
                        tooltip: l10n.devLottieControlPlay,
                      ),
                      // 一時停止ボタン
                      IconButton.filledTonal(
                        onPressed: controller.stop,
                        icon: const Icon(Icons.pause),
                        tooltip: l10n.devLottieControlPause,
                      ),
                      // 逆再生ボタン
                      IconButton.filledTonal(
                        onPressed: () => unawaited(controller.reverse()),
                        icon: const Icon(Icons.replay),
                        tooltip: l10n.devLottieControlReverse,
                      ),
                      // 停止（リセット）ボタン
                      IconButton.filledTonal(
                        onPressed: controller.reset,
                        icon: const Icon(Icons.stop),
                        tooltip: l10n.devLottieControlStop,
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // ループ再生切り替えスイッチ
                  SwitchListTile(
                    title: Text(l10n.devLottieLoop),
                    value: isLoop.value,
                    onChanged: (value) {
                      isLoop.value = value;
                      if (value && !controller.isAnimating) {
                        unawaited(controller.forward(from: controller.value));
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // アセット切り替えカード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.devLottieAssetSelect,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(assetList.length, (index) {
                      final item = assetList[index];
                      final isSelected = selectedIndex.value == index;
                      return ChoiceChip(
                        label: Text(item.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            selectedIndex.value = index;
                            controller.reset();
                            unawaited(controller.forward());
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ネットワークURL読み込み例カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_download_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.devLottieNetworkSection,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AppLottieWidget.network(url: "https://...")',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: AppLottieWidget.network(
                      url:
                          'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json',
                      width: 100,
                      height: 100,
                      animate: animate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
