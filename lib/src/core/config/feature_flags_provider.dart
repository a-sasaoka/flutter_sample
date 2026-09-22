import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/feature_flags.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'feature_flags_provider.g.dart';

/// フィーチャーフラグおよび動的バナーの状態を管理するNotifier
@Riverpod(keepAlive: true)
class FeatureFlagsNotifier extends _$FeatureFlagsNotifier {
  @override
  FeatureFlags build() {
    final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
    final talker = ref.watch(loggerProvider);

    // アプリ内デフォルト値（In-App Defaults）の設定
    unawaited(
      remoteConfig.setDefaults(const {
        'enable_qr_scanner': true,
        'announcement_banner_text': '',
      }),
    );

    // リアルタイム更新（Realtime Remote Config）の監視
    final subscription = remoteConfig.onConfigUpdated.listen(
      (event) async {
        try {
          await remoteConfig.activate();
          if (!ref.mounted) {
            return;
          }
          state = _getFlags(remoteConfig);
        } on Exception catch (e, st) {
          talker.handle(
            e,
            st,
            'Failed to activate updated remote config feature flags',
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        talker.handle(
          error,
          stackTrace,
          'Remote config onConfigUpdated stream error',
        );
      },
    );

    ref.onDispose(subscription.cancel);

    // バックグラウンドで最新値をフェッチ＆アクティベート
    unawaited(_fetchAndActivate(remoteConfig, talker));

    return _getFlags(remoteConfig);
  }

  Future<void> _fetchAndActivate(
    FirebaseRemoteConfig remoteConfig,
    Talker talker,
  ) async {
    try {
      final updated = await remoteConfig.fetchAndActivate();
      if (updated && ref.mounted) {
        state = _getFlags(remoteConfig);
      }
    } on Exception catch (e, st) {
      talker.handle(
        e,
        st,
        'Failed to fetch and activate remote config feature flags',
      );
    }
  }

  static FeatureFlags _getFlags(FirebaseRemoteConfig remoteConfig) {
    return FeatureFlags(
      isQrScannerEnabled: remoteConfig.getBool('enable_qr_scanner'),
      announcementMessage: remoteConfig.getString('announcement_banner_text'),
    );
  }
}
