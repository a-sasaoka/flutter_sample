// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart' as _lottie;

class $AssetsAnimationsGen {
  const $AssetsAnimationsGen();

  /// File path: assets/animations/empty_box.json
  LottieGenImage get emptyBox =>
      const LottieGenImage('assets/animations/empty_box.json');

  /// File path: assets/animations/not_found_404.json
  LottieGenImage get notFound404 =>
      const LottieGenImage('assets/animations/not_found_404.json');

  /// File path: assets/animations/onboarding_chat.json
  LottieGenImage get onboardingChat =>
      const LottieGenImage('assets/animations/onboarding_chat.json');

  /// File path: assets/animations/onboarding_memo.json
  LottieGenImage get onboardingMemo =>
      const LottieGenImage('assets/animations/onboarding_memo.json');

  /// File path: assets/animations/onboarding_sync.json
  LottieGenImage get onboardingSync =>
      const LottieGenImage('assets/animations/onboarding_sync.json');

  /// File path: assets/animations/success_check.json
  LottieGenImage get successCheck =>
      const LottieGenImage('assets/animations/success_check.json');

  /// List of all assets
  List<LottieGenImage> get values => [
    emptyBox,
    notFound404,
    onboardingChat,
    onboardingMemo,
    onboardingSync,
    successCheck,
  ];
}

abstract final class Assets {
  static const $AssetsAnimationsGen animations = $AssetsAnimationsGen();
}

class LottieGenImage {
  const LottieGenImage(this._assetName, {this.flavors = const {}});

  final String _assetName;
  final Set<String> flavors;

  _lottie.LottieBuilder lottie({
    Animation<double>? controller,
    bool? animate,
    _lottie.FrameRate? frameRate,
    bool? repeat,
    bool? reverse,
    _lottie.LottieDelegates? delegates,
    _lottie.LottieOptions? options,
    void Function(_lottie.LottieComposition)? onLoaded,
    _lottie.LottieImageProviderFactory? imageProviderFactory,
    Key? key,
    AssetBundle? bundle,
    Widget Function(BuildContext, Widget, _lottie.LottieComposition?)?
    frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    String? package,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    void Function(String)? onWarning,
    _lottie.LottieDecoder? decoder,
    _lottie.RenderCache? renderCache,
    bool? backgroundLoading,
  }) {
    return _lottie.Lottie.asset(
      _assetName,
      controller: controller,
      animate: animate,
      frameRate: frameRate,
      repeat: repeat,
      reverse: reverse,
      delegates: delegates,
      options: options,
      onLoaded: onLoaded,
      imageProviderFactory: imageProviderFactory,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      package: package,
      addRepaintBoundary: addRepaintBoundary,
      filterQuality: filterQuality,
      onWarning: onWarning,
      decoder: decoder,
      renderCache: renderCache,
      backgroundLoading: backgroundLoading,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
