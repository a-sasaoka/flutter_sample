import 'package:flutter_sample/src/features/map/data/spot_repository.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'spot_notifier.g.dart';

/// 🗺️ スポット一覧を管理・更新する Notifier
@riverpod
class SpotNotifier extends _$SpotNotifier {
  @override
  Future<List<MapSpot>> build() async {
    final repository = ref.read(spotRepositoryProvider);
    return repository.getSpots();
  }

  /// スポット一覧の手動再取得
  Future<void> fetchSpots() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(spotRepositoryProvider);
      return repository.getSpots();
    });
  }
}
