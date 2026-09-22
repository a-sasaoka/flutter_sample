import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/feature_flags_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class MockTalker extends Mock implements Talker {}

void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.current);
  });

  group('FeatureFlagsNotifier', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late MockTalker mockTalker;
    late StreamController<RemoteConfigUpdate> configUpdateController;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      mockTalker = MockTalker();
      configUpdateController = StreamController<RemoteConfigUpdate>.broadcast();

      when(() => mockRemoteConfig.setDefaults(any())).thenAnswer((_) async {});
      when(
        () => mockRemoteConfig.onConfigUpdated,
      ).thenAnswer((_) => configUpdateController.stream);
      when(
        () => mockRemoteConfig.fetchAndActivate(),
      ).thenAnswer((_) async => false);
      when(() => mockRemoteConfig.activate()).thenAnswer((_) async => true);
      when(
        () => mockRemoteConfig.getBool('enable_qr_scanner'),
      ).thenReturn(true);
      when(
        () => mockRemoteConfig.getString('announcement_banner_text'),
      ).thenReturn('');
    });

    tearDown(() async {
      await configUpdateController.close();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          firebaseRemoteConfigProvider.overrideWithValue(mockRemoteConfig),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('初期化時にデフォルト値を設定し、初期フラグを正しく返すこと', () {
      final container = createContainer();
      final flags = container.read(featureFlagsProvider);

      check(flags.isQrScannerEnabled).equals(true);
      check(flags.announcementMessage).equals('');

      verify(
        () => mockRemoteConfig.setDefaults(const {
          'enable_qr_scanner': true,
          'announcement_banner_text': '',
        }),
      ).called(1);
    });

    test('setDefaultsで例外が発生した際、talker.handleが呼ばれ初期フラグを維持すること', () async {
      final exception = Exception('Set defaults failed');
      when(() => mockRemoteConfig.setDefaults(any())).thenThrow(exception);

      final container = createContainer();
      check(
        container.read(featureFlagsProvider).isQrScannerEnabled,
      ).equals(true);

      await pumpEventQueue();

      verify(
        () => mockTalker.handle(
          exception,
          any(),
          'Failed to set remote config defaults',
        ),
      ).called(1);
    });

    test('fetchAndActivateで更新があった場合、新しい設定値に状態が更新されること', () async {
      when(
        () => mockRemoteConfig.fetchAndActivate(),
      ).thenAnswer((_) async => true);

      final container = createContainer();
      check(
        container.read(featureFlagsProvider).announcementMessage,
      ).equals('');

      when(
        () => mockRemoteConfig.getString('announcement_banner_text'),
      ).thenReturn('メンテナンス中');
      when(
        () => mockRemoteConfig.getBool('enable_qr_scanner'),
      ).thenReturn(false);

      await pumpEventQueue();

      final updatedFlags = container.read(featureFlagsProvider);
      check(updatedFlags.announcementMessage).equals('メンテナンス中');
      check(updatedFlags.isQrScannerEnabled).equals(false);
    });

    test('fetchAndActivateで例外が発生した際、talker.handleが呼ばれ安全に継続すること', () async {
      final exception = Exception('Network error');
      when(() => mockRemoteConfig.fetchAndActivate()).thenThrow(exception);

      final container = createContainer();
      check(
        container.read(featureFlagsProvider).announcementMessage,
      ).equals('');

      await pumpEventQueue();

      check(
        container.read(featureFlagsProvider).isQrScannerEnabled,
      ).equals(true);
      verify(
        () => mockTalker.handle(
          exception,
          any(),
          'Failed to fetch and activate remote config feature flags',
        ),
      ).called(1);
    });

    test('onConfigUpdatedでリアルタイム更新が届いた場合、即座に状態が更新されること', () async {
      final container = createContainer();

      check(
        container.read(featureFlagsProvider).announcementMessage,
      ).equals('');

      when(
        () => mockRemoteConfig.getString('announcement_banner_text'),
      ).thenReturn('重要なお知らせ');

      configUpdateController.add(
        RemoteConfigUpdate({'announcement_banner_text'}),
      );
      await pumpEventQueue();

      verify(() => mockRemoteConfig.activate()).called(1);
      check(
        container.read(featureFlagsProvider).announcementMessage,
      ).equals('重要なお知らせ');
    });

    test('onConfigUpdatedでactivateに失敗した際、talker.handleが呼ばれること', () async {
      final exception = Exception('Activate failed');
      when(() => mockRemoteConfig.activate()).thenThrow(exception);

      createContainer().read(featureFlagsProvider);

      configUpdateController.add(
        RemoteConfigUpdate({'announcement_banner_text'}),
      );
      await pumpEventQueue();

      verify(
        () => mockTalker.handle(
          exception,
          any(),
          'Failed to activate updated remote config feature flags',
        ),
      ).called(1);
    });

    test('onConfigUpdatedのストリームエラー発生時、onErrorでtalker.handleが呼ばれること', () async {
      final error = Exception('Stream error');
      createContainer().read(featureFlagsProvider);

      configUpdateController.addError(error);
      await pumpEventQueue();

      verify(
        () => mockTalker.handle(
          error,
          any(),
          'Remote config onConfigUpdated stream error',
        ),
      ).called(1);
    });

    test('Container破棄時にonConfigUpdatedリスナーが解除されること', () async {
      final container = ProviderContainer(
        overrides: [
          firebaseRemoteConfigProvider.overrideWithValue(mockRemoteConfig),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      )..read(featureFlagsProvider);

      check(configUpdateController.hasListener).equals(true);

      container.dispose();
      await pumpEventQueue();

      check(configUpdateController.hasListener).equals(false);
    });
  });
}
