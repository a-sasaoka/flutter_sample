import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/storage/image_cache_service.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/app_cached_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🖼️ 画像キャッシュ（CachedNetworkImage）のデモ・検証画面
///
/// 四角形・角丸・円形アバターの各形状表示、プレースホルダー（Shimmer）、
/// 読み込み失敗時のフォールバック、キャッシュ一括クリアの動作を確認できます。
class ImageCacheDemoScreen extends ConsumerWidget {
  /// コンストラクタ
  const ImageCacheDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final envConfig = ref.watch(envConfigProvider);
    final baseUrl = envConfig.imageBaseUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devImageCacheTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. キャッシュクリア操作カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    key: const Key('clear_image_cache_button'),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: Text(l10n.devImageCacheClearButton),
                    onPressed: () async {
                      try {
                        await ref.read(imageCacheServiceProvider).clearCache();
                        if (context.mounted) {
                          context.showSnackBar(
                            l10n.devImageCacheClearSuccess,
                            type: SnackBarType.success,
                          );
                        }
                      } on Exception catch (e, st) {
                        ref
                            .read(loggerProvider)
                            .handle(
                              e,
                              st,
                              'Failed to clear image cache',
                            );
                        if (context.mounted) {
                          context.showSnackBar(
                            l10n.devImageCacheClearError(e.toString()),
                            type: SnackBarType.error,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. 通常（四角形）画像デモ
          _DemoCard(
            title: l10n.devImageCacheStandard,
            child: AppCachedImage(
              key: const Key('regular_cached_image'),
              imageUrl: '$baseUrl/seed/rectangle/400/200',
              width: double.infinity,
              height: 180,
            ),
          ),
          const SizedBox(height: 16),

          // 3. 角丸（Rounded）画像デモ
          _DemoCard(
            title: l10n.devImageCacheRounded,
            child: AppCachedImage.rounded(
              key: const Key('rounded_cached_image'),
              imageUrl: '$baseUrl/seed/rounded/400/200',
              borderRadius: BorderRadius.circular(16),
              width: double.infinity,
              height: 180,
            ),
          ),
          const SizedBox(height: 16),

          // 4. 円形アバター（Circle）デモ
          _DemoCard(
            title: l10n.devImageCacheCircle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppCachedImage.circle(
                  key: const Key('circle_cached_image_1'),
                  imageUrl: '$baseUrl/seed/avatar1/150/150',
                  size: 64,
                ),
                AppCachedImage.circle(
                  key: const Key('circle_cached_image_2'),
                  imageUrl: '$baseUrl/seed/avatar2/150/150',
                  size: 64,
                ),
                AppCachedImage.circle(
                  key: const Key('circle_cached_image_3'),
                  imageUrl: '$baseUrl/seed/avatar3/150/150',
                  size: 64,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. 存在しないURL（エラー時のフォールバック表示）デモ
          _DemoCard(
            title: l10n.devImageCacheErrorUrl,
            child: const Center(
              child: AppCachedImage.rounded(
                key: Key('error_cached_image'),
                imageUrl: 'https://invalid-domain.example/not_found.png',
                borderRadius: BorderRadius.all(Radius.circular(12)),
                width: 140,
                height: 100,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. 未設定URL（null/空文字時の即時フォールバック表示）デモ
          _DemoCard(
            title: l10n.devImageCacheEmptyUrl,
            child: const Center(
              child: AppCachedImage.circle(
                key: Key('empty_cached_image'),
                imageUrl: null,
                size: 64,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 各デモセクション用の共通カードウィジェット
class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
