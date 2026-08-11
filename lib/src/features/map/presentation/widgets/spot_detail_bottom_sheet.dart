import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';

/// 📍 スポット詳細情報を表示するモーダルボトムシート
class SpotDetailBottomSheet extends StatelessWidget {
  /// コンストラクタ
  const SpotDetailBottomSheet({
    required this.spot,
    super.key,
    this.onStartRoutePressed,
  });

  /// 表示対象のスポット
  final MapSpot spot;

  /// ルート案内開始ボタンタップ時のコールバック
  final VoidCallback? onStartRoutePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: カテゴリバッジ & タイトル
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: spot.category.color.withValues(alpha: 0.2),
                  child: Icon(
                    spot.category.icon,
                    color: spot.category.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.category.localizedName(l10n),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: spot.category.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        spot.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (spot.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          spot.rating!.toStringAsFixed(1),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // 住所表示
            if (spot.address != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spot.address!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 詳細説明
            if (spot.description != null) ...[
              Text(
                spot.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // アクションボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('spotDetailStartRouteButton'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onStartRoutePressed?.call();
                },
                icon: const Icon(Icons.directions),
                label: Text(l10n.mapSpotStartRoute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
