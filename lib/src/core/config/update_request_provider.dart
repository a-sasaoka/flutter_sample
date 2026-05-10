import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_service.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_request_provider.g.dart';

// coverage:ignore-start
/// FirebaseRemoteConfigのインスタンスを提供するプロバイダ
@Riverpod(keepAlive: true)
FirebaseRemoteConfig firebaseRemoteConfig(Ref ref) {
  return FirebaseRemoteConfig.instance;
}
// coverage:ignore-end

/// UpdateServiceを提供するプロバイダ
@Riverpod(keepAlive: true)
UpdateService updateService(Ref ref) {
  return UpdateService(
    remoteConfig: ref.watch(firebaseRemoteConfigProvider),
    packageInfo: ref.watch(packageInfoProvider),
    getCurrentDateTime: () => ref.read(currentDateTimeProvider),
    talker: ref.watch(loggerProvider),
  );
}

/// RemoteConfigからアップデート情報を取得するコントローラ
@Riverpod(keepAlive: true)
class UpdateRequestController extends _$UpdateRequestController {
  @override
  Future<UpdateRequestType> build() async {
    // DIでモックを注入できるように、プロバイダ経由で取得
    final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
    final service = ref.watch(updateServiceProvider);

    // タイムアウトとフェッチのインターバル時間を設定
    final flavor = ref.watch(flavorProvider);
    final interval = flavor == Flavor.prod
        ? const Duration(hours: 12)
        : Duration.zero;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: interval,
      ),
    );

    // RemoteConfigの変更を監視（build内で行い、disposeで破棄する）
    final subscription = remoteConfig.onConfigUpdated.listen((event) async {
      await remoteConfig.activate();

      // Providerがすでに破棄されていたら何もしない
      if (!ref.mounted) return;

      // キャンセルフラグをリセット
      ref.read(cancelControllerProvider.notifier).reset();
      // stateをローディングに変更
      state = const AsyncValue.loading();
      // 変更した状態をstateに設定
      state = await AsyncValue.guard(() async {
        return service.getUpdateRequestType();
      });
    });

    ref.onDispose(subscription.cancel);

    // アクティベート
    await remoteConfig.fetchAndActivate();

    return service.getUpdateRequestType();
  }
}

/// アップデート情報のキャンセル有無を管理するコントローラ
@Riverpod(keepAlive: true)
class CancelController extends _$CancelController {
  @override
  bool build() {
    return false;
  }

  /// キャンセル押下
  void clickCancel() {
    state = true;
  }

  /// 状態リセット
  void reset() {
    state = false;
  }
}

/// アップデート通知種別
enum UpdateRequestType {
  /// アップデートなし
  not,

  /// 後回しを許容するアップデートあり
  cancelable,

  /// 強制的なアップデートあり
  forcibly,
}
