import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/update_info.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:version/version.dart';

/// アップデートの要否判定を行うサービス
class UpdateService {
  /// コンストラクタ
  const UpdateService({
    required FirebaseRemoteConfig remoteConfig,
    required PackageInfo packageInfo,
    required DateTime Function() getCurrentDateTime,
    required Talker talker,
  }) : _remoteConfig = remoteConfig,
       _packageInfo = packageInfo,
       _getCurrentDateTime = getCurrentDateTime,
       _talker = talker;

  final FirebaseRemoteConfig _remoteConfig;
  final PackageInfo _packageInfo;
  final DateTime Function() _getCurrentDateTime;
  final Talker _talker;

  /// RemoteConfigから情報を取得し、アップデート種別を判定する
  Future<UpdateRequestType> getUpdateRequestType() async {
    try {
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
      final currentVersion = Version.parse(_packageInfo.version);

      // RemoteConfigに設定されている要求バージョンと適用日を取得
      final requiredVersion = Version.parse(entity.requiredVersion);
      final enabledAt = entity.enabledAt;

      // 現在のバージョンより新しいバージョンが要求されているか
      final hasNewVersion = requiredVersion > currentVersion;
      // 指定された適用日時を過ぎているか
      final isEnabled = enabledAt.isBefore(_getCurrentDateTime());

      if (!isEnabled || !hasNewVersion) {
        // 有効期間外、もしくは新しいバージョンは無い
        return UpdateRequestType.not;
      }

      // キャンセル可能かどうかに基づいて種別を返す
      return entity.canCancel
          ? UpdateRequestType.cancelable
          : UpdateRequestType.forcibly;
    } on Exception catch (e) {
      _talker.warning('Failed to retrieve or parse the update information: $e');
      // 失敗時は安全のため「アップデートなし」として扱う
      return UpdateRequestType.not;
    }
  }
}
