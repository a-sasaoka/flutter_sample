import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🗺️ ネイティブ地図描画・現在地移動・住所ランドマーク検索を行う MapScreen
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

    // コントローラ未初期化時に受信した保留中の位置情報を保持
    final pendingPositionState = useState<Position?>(null);

    // 検索マーカーの集合を保持
    final markersState = useState<Set<Marker>>({});

    // 検索入力コントローラの生成と変更検知
    final searchController = useTextEditingController();
    useListenable(searchController);

    // MapNotifier の状態を監視
    final locationState = ref.watch(mapProvider);

    // MapSearchNotifier の状態を監視
    final searchState = ref.watch(mapSearchProvider);

    // 状態変化に伴うカメラ移動や対話ダイアログのリスナー
    ref
      ..listen(mapProvider, (previous, next) {
        next.whenOrNull(
          success: (position) {
            final controller = mapControllerState.value;
            if (controller != null) {
              // 現在地へスムーズにカメラアニメーション移動
              unawaited(
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(position.latitude, position.longitude),
                      zoom: 16,
                    ),
                  ),
                ),
              );
            } else {
              // 地図コントローラ生成前は保留状態として保持
              pendingPositionState.value = position;
            }
          },
          permissionDenied: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapPermissionDenied),
              ),
            );
          },
          permissionDeniedForever: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.mapPermissionDeniedForever),
                action: SnackBarAction(
                  label: l10n.mapOpenSettings,
                  onPressed: () {
                    unawaited(ref.read(mapProvider.notifier).openAppSettings());
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
                content: Text(l10n.mapFetchError(message)),
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
                content: Text(l10n.mapSearchError(message)),
              ),
            );
          },
        );
      });

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
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.mapSearchHint,
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  key: const Key('mapSearchClearButton'),
                                  icon: const Icon(Icons.clear),
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
                        onSubmitted: (query) {
                          unawaited(
                            ref
                                .read(mapSearchProvider.notifier)
                                .searchLocation(query),
                          );
                        },
                      ),
                    ),
                    if (searchState is MapSearchStateLoading)
                      const Padding(
                        padding: EdgeInsets.all(12),
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
                        onPressed: () {
                          unawaited(
                            ref
                                .read(mapSearchProvider.notifier)
                                .searchLocation(searchController.text),
                          );
                        },
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
                  initialCameraPosition: _initialCameraPosition,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: markersState.value,
                  onMapCreated: (controller) {
                    mapControllerState.value = controller;
                    final pendingPosition = pendingPositionState.value;
                    if (pendingPosition != null) {
                      unawaited(
                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                pendingPosition.latitude,
                                pendingPosition.longitude,
                              ),
                              zoom: 16,
                            ),
                          ),
                        ),
                      );
                      pendingPositionState.value = null;
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fetchLocationFab'),
        onPressed: () {
          unawaited(ref.read(mapProvider.notifier).fetchCurrentLocation());
        },
        icon: const Icon(Icons.my_location),
        label: Text(l10n.mapFetchLocation),
      ),
    );
  }
}
