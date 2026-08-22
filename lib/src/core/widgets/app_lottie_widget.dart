import 'package:flutter/material.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:lottie/lottie.dart';

/// 🎨 Lottie アニメーションを安全に表示するための共通 Widget
class AppLottieWidget extends StatelessWidget {
  /// [LottieGenImage]（flutter_gen 生成クラス）からアニメーションを作成するコンストラクタ
  const AppLottieWidget.asset({
    required LottieGenImage lottie,
    super.key,
    this.controller,
    this.animate,
    this.repeat = true,
    this.reverse = false,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onLoaded,
  }) : _lottieImage = lottie,
       _networkUrl = null;

  /// ネットワークURLからアニメーションを作成するコンストラクタ
  const AppLottieWidget.network({
    required String url,
    super.key,
    this.controller,
    this.animate,
    this.repeat = true,
    this.reverse = false,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onLoaded,
  }) : _lottieImage = null,
       _networkUrl = url;

  final LottieGenImage? _lottieImage;
  final String? _networkUrl;

  /// アニメーションコントローラー（再生・停止・シークバー操作用）
  final Animation<double>? controller;

  /// アニメーションを再生するかどうか（未指定時は実機でtrue、テスト環境でfalseに自動判別）
  final bool? animate;

  /// ループ再生するかどうか
  final bool repeat;

  /// 逆再生するかどうか
  final bool reverse;

  /// 横幅
  final double? width;

  /// 高さ
  final double? height;

  /// フィットモード
  final BoxFit fit;

  /// アニメーションデータの読み込み完了時コールバック
  final void Function(LottieComposition)? onLoaded;

  bool get _effectiveAnimate {
    if (animate != null) {
      return animate!;
    }
    // テスト環境実行時は pumpAndSettle のタイムアウトを防ぐため自動的に静止画にします
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return !bindingType.contains('Test');
  }

  @override
  Widget build(BuildContext context) {
    if (_networkUrl case final String url) {
      return Lottie.network(
        url,
        controller: controller,
        animate: _effectiveAnimate,
        repeat: repeat,
        reverse: reverse,
        width: width,
        height: height,
        fit: fit,
        onLoaded: onLoaded,
        errorBuilder: (context, error, stackTrace) => _FallbackIcon(
          width: width,
          height: height,
        ),
      );
    }

    final lottie = _lottieImage!;
    return lottie.lottie(
      controller: controller,
      animate: _effectiveAnimate,
      repeat: repeat,
      reverse: reverse,
      width: width,
      height: height,
      fit: fit,
      onLoaded: onLoaded,
      errorBuilder: (context, error, stackTrace) => _FallbackIcon(
        width: width,
        height: height,
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final size = width ?? height ?? 64;
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Icon(
          Icons.animation,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
