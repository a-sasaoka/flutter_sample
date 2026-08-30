import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sample/src/core/storage/image_cache_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

/// 画像の表示形状を表す列挙型
enum AppImageShape {
  /// 四角形（通常）
  rectangle,

  /// 角丸
  rounded,

  /// 円形（アバター）
  circle,
}

/// 共通のネットワーク画像キャッシュコンポーネント
///
/// - `cached_network_image` による端末ストレージへの自動キャッシュ
/// - `memCacheWidth` / `memCacheHeight` によるメモリ消費の最適化（OOM防止）
/// - 読み込み中のシマー（Shimmer）ローディング表示
/// - 画像URLが未設定（null/空文字）または読み込み失敗時のフォールバック表示
/// - 予期せぬ例外発生時の Talker への記録（CustomTalkerObserver経由でCrashlyticsに送信）
class AppCachedImage extends ConsumerWidget {
  /// 通常（四角形）コンストラクタ
  const AppCachedImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheManager,
  }) : shape = AppImageShape.rectangle,
       size = null;

  /// 角丸（Rounded）コンストラクタ
  const AppCachedImage.rounded({
    required this.imageUrl,
    required BorderRadius this.borderRadius,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheManager,
  }) : shape = AppImageShape.rounded,
       size = null;

  /// 円形アバター（Circle）コンストラクタ
  const AppCachedImage.circle({
    required this.imageUrl,
    required double this.size,
    super.key,
    this.fallbackWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheManager,
  }) : shape = AppImageShape.circle,
       width = size,
       height = size,
       fit = BoxFit.cover,
       borderRadius = null;

  /// 読み込む画像URL（nullまたは空文字の場合はフォールバックを表示）
  final String? imageUrl;

  /// 横幅
  final double? width;

  /// 高さ
  final double? height;

  /// 円形時のサイズ（直径）
  final double? size;

  /// 表示のフィッティング方式
  final BoxFit fit;

  /// 形状
  final AppImageShape shape;

  /// 角丸の半径（shapeがroundedの場合）
  final BorderRadius? borderRadius;

  /// URLが未設定またはエラー時に表示するウィジェット（未指定時はデフォルトアイコン）
  final Widget? fallbackWidget;

  /// メモリ上に展開する最大横幅（解像度の高い画像のメモリ消費を抑える）
  final int? memCacheWidth;

  /// メモリ上に展開する最大高さ
  final int? memCacheHeight;

  /// キャッシュマネージャー（テストやカスタマイズ用）
  final BaseCacheManager? cacheManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveFallback =
        fallbackWidget ??
        _DefaultFallback(
          width: width,
          height: height,
          shape: shape,
        );

    // URLが未指定または空文字の場合は、通信を行わず即座にフォールバックを表示
    final url = imageUrl?.trim();
    if (url case null || '') {
      return _applyShape(effectiveFallback);
    }

    // メモリキャッシュサイズを自動計算（指定がない場合はウィジェットの描画サイズ×デバイスピクセル比）
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    int? toMemSize(int? explicit, double? size) => switch ((explicit, size)) {
      (final int exp, _) => exp,
      (null, final double s) when s.isFinite => (s * pixelRatio).round(),
      _ => null,
    };
    final calculatedMemWidth = toMemSize(memCacheWidth, width);
    final calculatedMemHeight = toMemSize(memCacheHeight, height);

    final imageWidget = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      cacheManager: cacheManager ?? ref.watch(imageCacheManagerProvider),
      memCacheWidth: calculatedMemWidth,
      memCacheHeight: calculatedMemHeight,
      placeholder: (context, url) => _ShimmerPlaceholder(
        width: width,
        height: height,
        shape: shape,
      ),
      errorWidget: (context, url, error) {
        // 画像読み込み失敗時のエラーを Talker 経由で安全に記録（クエリパラメータはサニタイズ）
        final sanitizedUrl = _sanitizeUrl(url);
        ref
            .watch(loggerProvider)
            .handle(
              error,
              StackTrace.current,
              'Failed to load cached image ($sanitizedUrl)',
            );
        return effectiveFallback;
      },
    );

    return _applyShape(imageWidget);
  }

  /// URLからクエリパラメータ等を除去してログ記録用にサニタイズ
  static String _sanitizeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return url;
    }
    if (uri.hasQuery) {
      final sanitized = Uri(
        scheme: uri.scheme.isEmpty ? null : uri.scheme,
        userInfo: uri.userInfo.isEmpty ? null : uri.userInfo,
        host: uri.host.isEmpty ? null : uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
        fragment: uri.hasFragment ? uri.fragment : null,
      );
      return sanitized.toString();
    }
    return url;
  }

  /// 形状に応じたクリッピング・装飾を適用
  Widget _applyShape(Widget child) {
    return switch (shape) {
      AppImageShape.circle => ClipOval(
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
      AppImageShape.rounded => ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
      AppImageShape.rectangle => SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    };
  }
}

/// 読み込み中のシマープレースホルダー
class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({
    this.width,
    this.height,
    this.shape = AppImageShape.rectangle,
  });

  final double? width;
  final double? height;
  final AppImageShape shape;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    final isTest = bindingType.contains('Test');

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      enabled: !isTest,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }
}

/// デフォルトのフォールバック（人物アイコン）
class _DefaultFallback extends StatelessWidget {
  const _DefaultFallback({
    this.width,
    this.height,
    this.shape = AppImageShape.rectangle,
  });

  final double? width;
  final double? height;
  final AppImageShape shape;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.person_outline,
          color: colorScheme.onSurfaceVariant,
          size: switch ((width, height)) {
            (final double w, final double h) => (w < h ? w : h) * 0.5,
            _ => 24,
          },
        ),
      ),
    );
  }
}
