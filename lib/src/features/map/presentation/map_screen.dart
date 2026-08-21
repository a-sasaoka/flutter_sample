import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/application/map_route_notifier.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/application/spot_notifier.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_route_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/route_navigation_card.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/spot_detail_bottom_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🗺️ ネイティブ地図描画・現在地移動・住所ランドマーク検索・ルート案内を行う MapScreen
class MapScreen extends HookConsumerWidget {
  /// コンストラクタ
  const MapScreen({super.key});

  /// デフォルトの初期表示位置 (東京駅周辺)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 14.4,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // GoogleMapController のインスタンスを保持
    final mapControllerState = useState<GoogleMapController?>(null);

    // コントローラ未初期化時に受信した保留中のカメラターゲット座標を保持
    final pendingLatLngState = useState<LatLng?>(null);

    // コントローラ未初期化時に受信した保留中のルート境界領域 (LatLngBounds) を保持
    final pendingBoundsState = useState<LatLngBounds?>(null);

    // 検索マーカーの集合を保持
    final markersState = useState<Set<Marker>>({});

    // 検索入力コントローラの生成と変更検知
    final searchController = useTextEditingController();
    useListenable(searchController);

    // 検索バーのフォーカスノード
    final searchFocusNode = useFocusNode();

    // ルート案内カードの展開/折りたたみ状態（デフォルト: 詳細表示）
    final isRouteCardExpandedState = useState<bool>(true);

    // 検索バーにフォーカスが当たった際はルート案内カードを自動折りたたみ
    useEffect(() {
      void onFocusChange() {
        if (searchFocusNode.hasFocus) {
          isRouteCardExpandedState.value = false;
        }
      }

      searchFocusNode.addListener(onFocusChange);
      return () => searchFocusNode.removeListener(onFocusChange);
    }, [searchFocusNode]);

    // MapNotifier の状態を監視
    final locationState = ref.watch(mapProvider);

    // MapSearchNotifier の状態を監視
    final searchState = ref.watch(mapSearchProvider);

    // SpotNotifier のスポット一覧状態を監視
    final spotsState = ref.watch(spotProvider);

    // MapRouteNotifier のルート状態を監視
    final routeState = ref.watch(mapRouteProvider);

    // スポット一覧から GoogleMap 用のカスタムマーカー集合を生成
    final spotMarkers = spotsState.maybeWhen(
      data: (spots) => spots.map<Marker>((spot) {
        final latLng = LatLng(spot.latitude, spot.longitude);
        return Marker(
          markerId: MarkerId('spot_${spot.id}'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(spot.category.markerHue),
          infoWindow: InfoWindow(
            title: spot.name,
            snippet: spot.address,
          ),
          onTap: () {
            final controller = mapControllerState.value;
            if (controller != null) {
              unawaited(
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: latLng,
                      zoom: 16,
                    ),
                  ),
                ),
              );
            }
            unawaited(
              showModalBottomSheet<void>(
                context: context,
                builder: (modalContext) {
                  return SpotDetailBottomSheet(
                    spot: spot,
                    onStartRoutePressed: () {
                      final currentLocation =
                          locationState.whenOrNull(
                            success: (pos) =>
                                LatLng(pos.latitude, pos.longitude),
                          ) ??
                          _initialCameraPosition.target;

                      unawaited(
                        ref
                            .read(mapRouteProvider.notifier)
                            .searchRoute(
                              origin: currentLocation,
                              destination: latLng,
                              destinationName: spot.name,
                            ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      }).toSet(),
      orElse: () => <Marker>{},
    );

    // 全マーカーの結合 (スポットマーカー + 検索マーカー)
    final allMarkers = <Marker>{...spotMarkers, ...markersState.value};

    // ルート案内時の Polyline 集合を生成
    final polylines = routeState.maybeWhen(
      success: (route) => {
        Polyline(
          polylineId: PolylineId(route.id),
          points: route.points,
          color: Theme.of(context).colorScheme.primary,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      },
      orElse: () => <Polyline>{},
    );

    // 状態変化に伴うカメラ移動や対話ダイアログのリスナー
    ref
      ..listen(mapProvider, (previous, next) {
        next.whenOrNull(
          success: (position) {
            final latLng = LatLng(position.latitude, position.longitude);
            final controller = mapControllerState.value;
            if (controller != null) {
              // 現在地へスムーズにカメラアニメーション移動
              unawaited(
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: latLng,
                      zoom: 16,
                    ),
                  ),
                ),
              );
            } else {
              // 地図コントローラ生成前は保留状態として保持
              pendingLatLngState.value = latLng;
            }
          },
          permissionDenied: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.mapPermissionDenied)),
            );
          },
          permissionDeniedForever: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapPermissionDeniedForever),
                action: SnackBarAction(
                  label: l10n.mapOpenSettings,
                  onPressed: () {
                    unawaited(
                      ref.read(mapProvider.notifier).openAppSettings(),
                    );
                  },
                ),
              ),
            );
          },
          serviceDisabled: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapServiceDisabled),
                action: SnackBarAction(
                  label: l10n.mapOpenSettings,
                  onPressed: () {
                    unawaited(
                      ref.read(mapProvider.notifier).openLocationSettings(),
                    );
                  },
                ),
              ),
            );
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapFetchError),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
      })
      ..listen(mapSearchProvider, (previous, next) {
        next.whenOrNull(
          success: (locations, query) {
            if (locations.isEmpty) {
              return;
            }

            if (locations.length == 1) {
              final target = locations.first;
              final latLng = LatLng(target.latitude, target.longitude);
              markersState.value = {
                Marker(
                  markerId: const MarkerId('search_result'),
                  position: latLng,
                  infoWindow: InfoWindow(
                    title: target.name,
                    snippet: target.address,
                  ),
                ),
              };
              final controller = mapControllerState.value;
              if (controller != null) {
                unawaited(
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: latLng,
                        zoom: 16,
                      ),
                    ),
                  ),
                );
              } else {
                pendingLatLngState.value = latLng;
              }
            } else {
              // 複数候補がある場合は候補選択ボトムシートを表示
              unawaited(
                showModalBottomSheet<void>(
                  context: context,
                  builder: (modalContext) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              l10n.mapSearchSelectCandidateTitle,
                              style: Theme.of(
                                modalContext,
                              ).textTheme.titleMedium,
                            ),
                          ),
                          const Divider(height: 1),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: locations.length,
                              itemBuilder: (context, index) {
                                final candidate = locations[index];
                                return ListTile(
                                  key: Key('mapCandidateTile_$index'),
                                  leading: const Icon(
                                    Icons.place,
                                    color: Colors.red,
                                  ),
                                  title: Text(candidate.name),
                                  subtitle: candidate.address != null
                                      ? Text(candidate.address!)
                                      : null,
                                  trailing: candidate.rating != null
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              candidate.rating!.toStringAsFixed(
                                                1,
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.of(modalContext).pop();
                                    final latLng = LatLng(
                                      candidate.latitude,
                                      candidate.longitude,
                                    );
                                    markersState.value = {
                                      Marker(
                                        markerId: MarkerId(
                                          'search_result_$index',
                                        ),
                                        position: latLng,
                                        infoWindow: InfoWindow(
                                          title: candidate.name,
                                          snippet: candidate.address,
                                        ),
                                      ),
                                    };
                                    final controller = mapControllerState.value;
                                    if (controller != null) {
                                      unawaited(
                                        controller.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: latLng,
                                              zoom: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      pendingLatLngState.value = latLng;
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          },
          empty: (query) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapSearchEmpty(query)),
              ),
            );
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapSearchError),
              ),
            );
          },
        );
      })
      ..listen(mapRouteProvider, (previous, next) {
        next.whenOrNull(
          success: (route) {
            isRouteCardExpandedState.value = !searchFocusNode.hasFocus;
            final controller = mapControllerState.value;
            if (controller != null) {
              unawaited(
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(route.bounds, 64),
                ),
              );
            } else {
              pendingBoundsState.value = route.bounds;
            }
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapRouteError),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
      });

    // 検索実行ヘルパー（フォーカス解除 + 前のルート自動クリア + 検索開始）
    void executeSearch(String query) {
      searchFocusNode.unfocus();
      ref.read(mapRouteProvider.notifier).clearRoute();
      unawaited(
        ref.read(mapSearchProvider.notifier).searchLocation(query),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
      ),
      body: Column(
        children: [
          // 上部 検索バー UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('mapSearchTextField'),
                        controller: searchController,
                        focusNode: searchFocusNode,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.mapSearchHint,
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  key: const Key('mapSearchClearButton'),
                                  icon: const Icon(Icons.clear),
                                  tooltip: l10n.mapSearchClear,
                                  onPressed: () {
                                    searchController.clear();
                                    markersState.value = {};
                                    ref
                                        .read(mapSearchProvider.notifier)
                                        .clearSearch();
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: executeSearch,
                      ),
                    ),
                    if (searchState is MapSearchStateLoading)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        key: const Key('mapSearchButton'),
                        icon: const Icon(Icons.send),
                        onPressed: () => executeSearch(searchController.text),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 地図 & ローディングオーバーレイ
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      locationState.whenOrNull(
                        success: (position) => CameraPosition(
                          target: LatLng(
                            position.latitude,
                            position.longitude,
                          ),
                          zoom: 16,
                        ),
                      ) ??
                      _initialCameraPosition,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: allMarkers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    mapControllerState.value = controller;
                    final pendingLatLng = pendingLatLngState.value;
                    if (pendingLatLng != null) {
                      unawaited(
                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: pendingLatLng,
                              zoom: 16,
                            ),
                          ),
                        ),
                      );
                      pendingLatLngState.value = null;
                    }
                    final pendingBounds = pendingBoundsState.value;
                    if (pendingBounds != null) {
                      unawaited(
                        controller.animateCamera(
                          CameraUpdate.newLatLngBounds(pendingBounds, 64),
                        ),
                      );
                      pendingBoundsState.value = null;
                    }
                  },
                ),

                // 位置情報ロード中インジケータ
                if (locationState is LocationStateLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                // ルート計算中インジケータ
                if (routeState is MapRouteStateLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                // 画面下部コントロール群 (現在地取得 FAB ＋ ルート案内カード)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16, bottom: 8),
                          child: FloatingActionButton.extended(
                            heroTag: null,
                            key: const Key('fetchLocationFab'),
                            onPressed: () {
                              unawaited(
                                ref
                                    .read(mapProvider.notifier)
                                    .fetchCurrentLocation(),
                              );
                            },
                            icon: const Icon(Icons.my_location),
                            label: Text(l10n.mapFetchLocation),
                          ),
                        ),
                        if (routeState is MapRouteStateSuccess)
                          RouteNavigationCard(
                            route: routeState.route,
                            isExpanded: isRouteCardExpandedState.value,
                            onToggleExpand: () {
                              isRouteCardExpandedState.value =
                                  !isRouteCardExpandedState.value;
                            },
                            onClose: () {
                              ref.read(mapRouteProvider.notifier).clearRoute();
                            },
                            onTravelModeChanged: (mode) {
                              if (mode != routeState.route.travelMode) {
                                unawaited(
                                  ref
                                      .read(mapRouteProvider.notifier)
                                      .searchRoute(
                                        origin: routeState.route.origin,
                                        destination:
                                            routeState.route.destination,
                                        destinationName:
                                            routeState.route.destinationName,
                                        travelMode: mode,
                                      ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
