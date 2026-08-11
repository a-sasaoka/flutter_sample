import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🗺️ ネイティブ地図描画と現在地カメラ移動を行う MapScreen (多言語化対応)
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

    // MapNotifier の状態を監視
    final locationState = ref.watch(mapProvider);

    // 状態変化に伴うカメラ移動や対話ダイアログのリスナー
    ref.listen(mapProvider, (previous, next) {
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
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
      ),
      body: Stack(
        children: [
          // GoogleMap ウィジェットの描画
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              mapControllerState.value = controller;
            },
          ),

          // ロード中インジケータ
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
