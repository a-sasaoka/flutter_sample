import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

// 1. モッククラスとフェイククラスの作成
class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class FakeRemoteConfigSettings extends Fake implements RemoteConfigSettings {}

class MockRemoteConfigUpdate extends Mock implements RemoteConfigUpdate {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late StreamController<RemoteConfigUpdate> configUpdateController;
  late MockTalker mockLogger;

  // テスト環境の「現在時刻」を固定（時間を止める魔法！）
  final mockCurrentTime = DateTime(2024, 1, 1, 12);

  // 全テスト共通のセットアップ
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeRemoteConfigSettings());
  });

  setUp(() {
    mockRemoteConfig = MockFirebaseRemoteConfig();
    configUpdateController = StreamController<RemoteConfigUpdate>.broadcast();
    mockLogger = MockTalker();

    // パッケージ情報（現在のアプリバージョン）を "1.0.0" に固定
    PackageInfo.setMockInitialValues(
      appName: 'TestApp',
      packageName: 'com.example.test',
      version: '1.0.0', // 現在のバージョン
      buildNumber: '1',
      buildSignature: '',
    );

    // FirebaseRemoteConfig の基本的な挙動をスタブ化
    when(
      () => mockRemoteConfig.setConfigSettings(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRemoteConfig.onConfigUpdated,
    ).thenAnswer((_) => configUpdateController.stream);
    when(
      () => mockRemoteConfig.fetchAndActivate(),
    ).thenAnswer((_) async => true);
    when(() => mockRemoteConfig.activate()).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await configUpdateController.close();
  });

  /// テスト用のProviderContainerを作成するヘルパー
  ProviderContainer createContainer({Flavor flavor = Flavor.dev}) {
    final mockPackageInfo = PackageInfo(
      appName: 'TestApp',
      packageName: 'com.example.test',
      version: '1.0.0',
      buildNumber: '1',
    );

    final container = ProviderContainer(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        firebaseRemoteConfigProvider.overrideWithValue(mockRemoteConfig),
        // プロバイダ経由で現在時刻を注入！
        currentDateTimeProvider.overrideWithValue(mockCurrentTime),
        packageInfoProvider.overrideWithValue(mockPackageInfo),
        loggerProvider.overrideWithValue(mockLogger),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// テスト用のJSON文字列を生成するヘルパー
  String createConfigJson({
    required String version,
    required DateTime enabledAt,
    required bool canCancel,
  }) {
    return json.encode({
      'requiredVersion': version,
      'enabledAt': enabledAt.toIso8601String(),
      'canCancel': canCancel,
    });
  }

  group('CancelController テスト', () {
    test('初期値は false であり、clickCancel/reset で状態が切り替わること', () {
      final container = createContainer();
      final notifier = container.read(cancelControllerProvider.notifier);

      expect(container.read(cancelControllerProvider), isFalse);

      notifier.clickCancel();
      expect(container.read(cancelControllerProvider), isTrue);

      notifier.reset();
      expect(container.read(cancelControllerProvider), isFalse);
    });
  });

  group('UpdateRequestController テスト', () {
    test('RemoteConfigの設定値が空文字列の場合は not(アップデートなし) を返すこと', () async {
      when(() => mockRemoteConfig.getString('update_info')).thenReturn('');

      final container = createContainer();
      final state = await container.read(
        updateRequestControllerProvider.future,
      );

      expect(state, equals(UpdateRequestType.not));
    });

    test('RemoteConfigのJSONが不正(パース失敗)な場合は例外をキャッチし not を返すこと', () async {
      when(
        () => mockRemoteConfig.getString('update_info'),
      ).thenReturn('invalid_json_format');

      final container = createContainer();
      final state = await container.read(
        updateRequestControllerProvider.future,
      );

      expect(state, equals(UpdateRequestType.not));
    });

    test('現在のバージョン(1.0.0) >= 要求バージョン(1.0.0) の場合は not を返すこと', () async {
      // 過去の日付（有効期間内）
      final pastTime = mockCurrentTime.subtract(const Duration(days: 1));
      final jsonStr = createConfigJson(
        version: '1.0.0',
        enabledAt: pastTime,
        canCancel: false,
      );
      when(() => mockRemoteConfig.getString('update_info')).thenReturn(jsonStr);

      final container = createContainer();
      final state = await container.read(
        updateRequestControllerProvider.future,
      );

      expect(state, equals(UpdateRequestType.not));
    });

    test('新しいバージョン(2.0.0)だが、有効期間外(未来)の場合は not を返すこと', () async {
      // 未来の日付（有効期間外）
      final futureTime = mockCurrentTime.add(const Duration(days: 1));
      final jsonStr = createConfigJson(
        version: '2.0.0',
        enabledAt: futureTime,
        canCancel: false,
      );
      when(() => mockRemoteConfig.getString('update_info')).thenReturn(jsonStr);

      final container = createContainer();
      final state = await container.read(
        updateRequestControllerProvider.future,
      );

      expect(state, equals(UpdateRequestType.not));
    });

    test(
      '新しいバージョン(2.0.0)で有効期間内、かつ canCancel=true の場合は cancelable を返すこと',
      () async {
        // 過去の日付（有効期間内）
        final pastTime = mockCurrentTime.subtract(const Duration(days: 1));
        final jsonStr = createConfigJson(
          version: '2.0.0',
          enabledAt: pastTime,
          canCancel: true,
        );
        when(
          () => mockRemoteConfig.getString('update_info'),
        ).thenReturn(jsonStr);

        final container = createContainer();
        final state = await container.read(
          updateRequestControllerProvider.future,
        );

        expect(state, equals(UpdateRequestType.cancelable));
      },
    );

    test(
      '新しいバージョン(2.0.0)で有効期間内、かつ canCancel=false の場合は forcibly を返すこと',
      () async {
        // 過去の日付（有効期間内）
        final pastTime = mockCurrentTime.subtract(const Duration(days: 1));
        final jsonStr = createConfigJson(
          version: '2.0.0',
          enabledAt: pastTime,
          canCancel: false,
        );
        when(
          () => mockRemoteConfig.getString('update_info'),
        ).thenReturn(jsonStr);

        final container = createContainer();
        final state = await container.read(
          updateRequestControllerProvider.future,
        );

        expect(state, equals(UpdateRequestType.forcibly));
      },
    );

    test('Flavorがprodの場合は minimumFetchInterval が12時間として設定されること', () async {
      when(() => mockRemoteConfig.getString('update_info')).thenReturn('');

      final container = createContainer(flavor: Flavor.prod);
      await container.read(updateRequestControllerProvider.future);

      final captured = verify(
        () => mockRemoteConfig.setConfigSettings(captureAny()),
      ).captured;
      final settings = captured.first as RemoteConfigSettings;
      expect(settings.minimumFetchInterval, equals(const Duration(hours: 12)));
    });

    test('RemoteConfigが更新されたとき、状態がloadingを経て最新データに更新されること', () async {
      // 1. 準備：初期データ（1.0.0）
      when(() => mockRemoteConfig.getString('update_info')).thenReturn(
        createConfigJson(
          version: '1.0.0',
          enabledAt: mockCurrentTime.subtract(const Duration(days: 1)),
          canCancel: false,
        ),
      );

      final container = createContainer();
      await container.read(updateRequestControllerProvider.future);

      // 2. 状態の変化を監視するための準備
      final states = <AsyncValue<UpdateRequestType>>[];
      container.listen<AsyncValue<UpdateRequestType>>(
        updateRequestControllerProvider,
        (previous, next) => states.add(next), // 状態が変わるたびにリストに追加
      );

      // 3. 2回目のデータの準備（2.0.0）
      when(() => mockRemoteConfig.getString('update_info')).thenReturn(
        createConfigJson(
          version: '2.0.0',
          enabledAt: mockCurrentTime.subtract(const Duration(days: 1)),
          canCancel: false,
        ),
      );

      // 4. 実行：ストリームに更新イベントを流し込む
      configUpdateController.add(MockRemoteConfigUpdate());

      // 5. 検証：AsyncDataになるまで待ち、かつイベントループを回しきる
      await container.read(updateRequestControllerProvider.future);
      // マイクロタスクを全て消化させるために一瞬待つ
      await Future<void>.delayed(Duration.zero);

      // 6. 履歴の検証
      expect(
        states.any((s) => s.isLoading),
        isTrue,
        reason: '状態遷移のどこかで一度はLoadingになっているべき',
      );
    });
  });
}
