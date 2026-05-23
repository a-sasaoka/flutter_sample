import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🎨 スプラッシュ画面のデザインカスタマイズ用定数
class SplashConfig {
  /// スプラッシュ表示時間（最小2秒）
  static const Duration displayDuration = Duration(seconds: 2);

  /// アニメーションの動作時間
  static const Duration animationDuration = Duration(milliseconds: 1500);

  /// 背景のグラデーション開始色（プライマリに近い色）
  static const Color gradientStartColor = Color(0xFF1E3C72);

  /// 背景のグラデーション終了色
  static const Color gradientEndColor = Color(0xFF2A5298);

  /// ロゴの色
  static const Color logoColor = Colors.white;

  /// ロゴのサイズ
  static const double logoSize = 100;
}

/// 🌊 スプラッシュ画面
///
/// 起動時に表示され、心地よいフェードイン＆バウンドアニメーションを行った後、
/// 最低表示時間である2秒を満たした時点で次の画面へ遷移します。
class SplashScreen extends HookConsumerWidget {
  /// コンストラクタ
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. アニメーションコントローラーの作成（flutter_hooks を使用）
    final animationController = useAnimationController(
      duration: SplashConfig.animationDuration,
    );

    // 2. フェードイン（不透明度）のアニメーションを定義
    final opacityAnimation = useMemoized(
      () => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animationController,
          curve: const Interval(0, 0.6, curve: Curves.easeIn),
        ),
      ),
      [animationController],
    );

    // 3. バウンド（ふわっと少し上に浮き上がる）のアニメーションを定義
    final slideAnimation = useMemoized(
      () => Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: const Interval(0.2, 1, curve: Curves.easeOutBack),
        ),
      ),
      [animationController],
    );

    // 4. 初回描画時にアニメーション開始とタイマーを起動
    useEffect(
      () {
        // アニメーションを開始
        unawaited(animationController.forward());

        // 最低2秒待ってから、スプラッシュ終了フラグを立てる
        final timer = Timer(SplashConfig.displayDuration, () {
          ref.read(splashStateProvider.notifier).finishSplash();
        });

        // クリーンアップ処理（アンマウント時にタイマーをキャンセル）
        return timer.cancel;
      },
      const [],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SplashConfig.gradientStartColor,
              SplashConfig.gradientEndColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, slideAnimation.value),
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: const SplashLogo(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 🎨 スプラッシュ画面の中央に表示されるロゴWidget
///
/// デザインを変更したい場合は、このWidget内の実装を書き換えます。
class SplashLogo extends StatelessWidget {
  /// コンストラクタ
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ロゴのアイコン
        Icon(
          Icons.flutter_dash,
          size: SplashConfig.logoSize,
          color: SplashConfig.logoColor,
        ),
        SizedBox(height: 16),
        // アプリタイトル
        Text(
          'Flutter Sample App',
          style: TextStyle(
            color: SplashConfig.logoColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
