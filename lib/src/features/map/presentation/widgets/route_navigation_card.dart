import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';

/// 目的地までの距離・所要時間および案内終了ボタンを表示するナビゲーションカード
class RouteNavigationCard extends StatelessWidget {
  /// コンストラクタ
  const RouteNavigationCard({
    required this.route,
    required this.onClose,
    this.onTravelModeChanged,
    super.key,
  });

  /// ナビゲーション対象のルート情報
  final MapRoute route;

  /// 案内終了ボタン押下時のコールバック
  final VoidCallback onClose;

  /// 移動手段変更時のコールバック
  final ValueChanged<TravelMode>? onTravelModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行: アイコン + 目的地名 + 閉じるボタン
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    route.destinationName ?? l10n.mapRouteNavigationTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const Key('routeNavigationCloseButton'),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.mapRouteClose,
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 移動手段切り替え SegmentedButton
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TravelMode>(
                segments: [
                  ButtonSegment(
                    value: TravelMode.driving,
                    icon: const Icon(Icons.directions_car, size: 18),
                    label: Text(l10n.mapTravelModeDriving),
                  ),
                  ButtonSegment(
                    value: TravelMode.walking,
                    icon: const Icon(Icons.directions_walk, size: 18),
                    label: Text(l10n.mapTravelModeWalking),
                  ),
                  ButtonSegment(
                    value: TravelMode.bicycling,
                    icon: const Icon(Icons.directions_bike, size: 18),
                    label: Text(l10n.mapTravelModeBicycling),
                  ),
                  ButtonSegment(
                    value: TravelMode.transit,
                    icon: const Icon(Icons.directions_transit, size: 18),
                    label: Text(l10n.mapTravelModeTransit),
                  ),
                ],
                selected: {route.travelMode},
                onSelectionChanged: (selected) {
                  if (selected.isNotEmpty) {
                    onTravelModeChanged?.call(selected.first);
                  }
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const Divider(height: 16),

            // ルート詳細情報: 所要時間 + 移動距離
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 所要時間
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mapRouteDuration,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          l10n.mapRouteMinutes(route.durationMinutes),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 区切り線
                Container(
                  width: 1,
                  height: 32,
                  color: theme.dividerColor,
                ),

                // 移動距離
                Row(
                  children: [
                    const Icon(
                      Icons.straighten,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mapRouteDistance,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          l10n.mapRouteKm(route.distanceKm),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // 徒歩・自転車または API からの警告メッセージ表示
            if (_getWarningMessage(l10n) case final warningMessage?) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('routeNavigationWarningBanner'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warningMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ルートの移動手段や API レスポンスに応じた警告・注意事項テキストを取得
  String? _getWarningMessage(AppLocalizations l10n) {
    if (route.warnings.isNotEmpty) {
      return route.warnings.join('\n');
    }
    return switch (route.travelMode) {
      TravelMode.walking => l10n.mapRouteWalkingWarning,
      TravelMode.bicycling => l10n.mapRouteBicyclingWarning,
      TravelMode.driving || TravelMode.transit => null,
    };
  }
}
