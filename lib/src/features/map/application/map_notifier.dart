import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/data/location_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_notifier.g.dart';

/// 🗺️ 地図画面のカメラ・位置情報取得状態を管理する Notifier
@Riverpod(keepAlive: true)
class MapNotifier extends _$MapNotifier {
  @override
  LocationState build() {
    return const LocationState.initial();
  }

  /// 現在地を取得し、状態を更新する
  Future<void> fetchCurrentLocation() async {
    final talker = ref.read(loggerProvider);
    final repository = ref.read(locationRepositoryProvider);

    state = const LocationState.loading();

    try {
      // 1. 位置情報サービス (GPS) が端末で有効か確認
      final isServiceEnabled = await repository.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        talker.warning('[MapNotifier] 位置情報サービスが無効です');
        state = const LocationState.serviceDisabled();
        return;
      }

      // 2. 権限状態の確認と要求
      var permission = await repository.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await repository.requestPermission();
        if (permission == LocationPermission.denied) {
          talker.warning('[MapNotifier] 位置情報権限が拒否されました');
          state = const LocationState.permissionDenied();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        talker.warning('[MapNotifier] 位置情報権限が永久拒否されました');
        state = const LocationState.permissionDeniedForever();
        return;
      }

      // 3. 現在位置の取得
      final position = await repository.getCurrentPosition();
      talker.info('[MapNotifier] 現在地取得成功');
      state = LocationState.success(position);
    } on Exception catch (e, st) {
      talker.handle(e, st);
      state = LocationState.error(e.toString());
    }
  }

  /// 端末の設定画面を開く
  Future<void> openAppSettings() async {
    final repository = ref.read(locationRepositoryProvider);
    await repository.openAppSettings();
  }

  /// 端末の位置情報設定画面を開く
  Future<void> openLocationSettings() async {
    final repository = ref.read(locationRepositoryProvider);
    await repository.openLocationSettings();
  }
}
