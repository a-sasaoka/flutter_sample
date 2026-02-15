import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/update_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:version/version.dart';

part 'update_request_provider.dart.g.dart';

/// RemoteConfigからアップデート情報を取得するコントローラ
@Riverpod(keepAlive: true)
class UpdateRequestController extends _$UpdateRequestController {
  /// コンストラクタ
  UpdateRequestController() {
    // RemoteConfigの変更を監視
    _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();

      // キャンセルフラグをリセット
      ref.read(cancelControllerProvider.notifier).reset();

      // stateをローディングに変更
      state = const AsyncValue.loading();

      // 変更した状態をstateに設定
      state = await AsyncValue.guard(() async {
        return _getRemoteConfigData();
      });
    });
  }

  /// RemoteConfigインスタンス
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  @override
  Future<UpdateRequestType> build() async {
    // タイムアウトとフェッチのインターバル時間を設定
    const interval = Duration.zero;
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: interval,
      ),
    );

    // アクティベート
    await _remoteConfig.fetchAndActivate();

    return _getRemoteConfigData();
  }

  /// RemoteConfigからアップデート情報を取得
  Future<UpdateRequestType> _getRemoteConfigData() async {
    // RemoteConfigから情報を取得
    final string = _remoteConfig.getString('update_info');
    if (string.isEmpty) {
      return UpdateRequestType.not;
    }

    // JSONをMapに変換
    final map = json.decode(string) as Map<String, Object?>;
    // JSONの情報からアップデート情報を作成
    final entity = UpdateInfo.fromJson(map);

    // 現在のアプリバージョンを取得
    final appPackageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(appPackageInfo.version);

    // RemoteConfigに設定されているバージョンと適用日を取得
    final requiredVersion = Version.parse(entity.requiredVersion);
    final enabledAt = entity.enabledAt;

    // 現在のバージョンより新しいバージョンが指定されているか
    final hasNewVersion = requiredVersion > currentVersion;
    // 強制アップデート有効期間内かどうか
    final isEnabled = enabledAt.compareTo(DateTime.now()) < 0;

    if (!isEnabled || !hasNewVersion) {
      // 有効期間外、もしくは新しいバージョンは無い
      return UpdateRequestType.not;
    }
    return entity.canCancel
        ? UpdateRequestType.cancelable
        : UpdateRequestType.forcibly;
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
