import 'dart:typed_data';
import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/share/application/share_service.dart';
import 'package:flutter_sample/src/features/share/domain/share_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockSharePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements SharePlatform {}

class MockUrlLauncherPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

/// アプリロック抑止をテスト内で安全に通過させる Fake サービス
class FakeAppLockService extends AppLockService {
  int suppressionCallCount = 0;

  @override
  Future<AppLockState> build() async => const AppLockState.disabled();

  @override
  Future<T> runWithLockSuppression<T>(Future<T> Function() action) async {
    suppressionCallCount++;
    return await action();
  }
}

void main() {
  late SharePlatform originalSharePlatform;
  late UrlLauncherPlatform originalUrlPlatform;
  late MockSharePlatform mockSharePlatform;
  late FakeAppLockService fakeAppLockService;
  late MockUrlLauncherPlatform mockUrlLauncherPlatform;
  late Talker talker;
  late ShareService service;

  setUpAll(() {
    originalSharePlatform = SharePlatform.instance;
    originalUrlPlatform = UrlLauncherPlatform.instance;

    registerFallbackValue(ShareParams());
    registerFallbackValue(const LaunchOptions());
  });

  tearDownAll(() {
    SharePlatform.instance = originalSharePlatform;
    UrlLauncherPlatform.instance = originalUrlPlatform;
  });

  setUp(() {
    mockSharePlatform = MockSharePlatform();
    SharePlatform.instance = mockSharePlatform;

    mockUrlLauncherPlatform = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncherPlatform;

    fakeAppLockService = FakeAppLockService();

    talker = Talker();
    service = ShareService(
      appLockService: fakeAppLockService,
      logger: talker,
      sharePlus: SharePlus.custom(mockSharePlatform),
    );
  });

  group('ShareService - shareText', () {
    test('正常にテキスト共有が成功した場合、ShareResult.success を返すこと', () async {
      const expectedResult = ShareResult(
        'com.apple.UIKit.activity.PostToTwitter',
        ShareResultStatus.success,
      );
      when(
        () => mockSharePlatform.share(any()),
      ).thenAnswer((_) async => expectedResult);

      final result = await service.shareText(
        text: 'テストメッセージ',
        subject: '件名テスト',
        sharePositionOrigin: const Rect.fromLTWH(10, 20, 30, 40),
      );

      check(result.status).equals(ShareResultStatus.success);
      check(result.raw).equals('com.apple.UIKit.activity.PostToTwitter');

      final captured =
          verify(() => mockSharePlatform.share(captureAny())).captured.single
              as ShareParams;
      check(captured.text).equals('テストメッセージ');
      check(captured.subject).equals('件名テスト');
      check(
        captured.sharePositionOrigin,
      ).equals(const Rect.fromLTWH(10, 20, 30, 40));

      check(fakeAppLockService.suppressionCallCount).equals(1);
    });

    test('ユーザーが共有をキャンセルした場合、ShareResult.dismissed を返すこと', () async {
      const expectedResult = ShareResult('', ShareResultStatus.dismissed);
      when(
        () => mockSharePlatform.share(any()),
      ).thenAnswer((_) async => expectedResult);

      final result = await service.shareText(text: 'キャンセルテスト');

      check(result.status).equals(ShareResultStatus.dismissed);
      check(fakeAppLockService.suppressionCallCount).equals(1);
    });

    test('共有が利用不可の場合、ShareResult.unavailable を返すこと', () async {
      const expectedResult = ShareResult('', ShareResultStatus.unavailable);
      when(
        () => mockSharePlatform.share(any()),
      ).thenAnswer((_) async => expectedResult);

      final result = await service.shareText(text: '利用不可テスト');

      check(result.status).equals(ShareResultStatus.unavailable);
      check(fakeAppLockService.suppressionCallCount).equals(1);
    });

    test(
      'sharePositionOrigin が未指定（null）の場合、ShareConfig のデフォルト座標が補完されること',
      () async {
        const expectedResult = ShareResult('', ShareResultStatus.success);
        when(
          () => mockSharePlatform.share(any()),
        ).thenAnswer((_) async => expectedResult);

        await service.shareText(text: 'デフォルト座標テスト');

        final captured =
            verify(() => mockSharePlatform.share(captureAny())).captured.single
                as ShareParams;
        check(
          captured.sharePositionOrigin,
        ).equals(ShareConfig.defaultSharePositionOrigin);
      },
    );
  });

  group('ShareService - shareXFiles', () {
    test('画像ファイルを共有し、結果を正しく返すこと', () async {
      const expectedResult = ShareResult('success', ShareResultStatus.success);
      when(
        () => mockSharePlatform.share(any()),
      ).thenAnswer((_) async => expectedResult);

      final testFile = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
        name: 'test.png',
      );

      final result = await service.shareXFiles(
        files: [testFile],
        text: '画像付きメッセージ',
        sharePositionOrigin: const Rect.fromLTWH(50, 50, 100, 100),
      );

      check(result.status).equals(ShareResultStatus.success);

      final captured =
          verify(() => mockSharePlatform.share(captureAny())).captured.single
              as ShareParams;
      check(captured.files).isNotNull();
      check(captured.files!.length).equals(1);
      check(captured.text).equals('画像付きメッセージ');
      check(
        captured.sharePositionOrigin,
      ).equals(const Rect.fromLTWH(50, 50, 100, 100));

      check(fakeAppLockService.suppressionCallCount).equals(1);
    });

    test(
      'shareXFiles で sharePositionOrigin が null の場合、デフォルト座標が使われること',
      () async {
        const expectedResult = ShareResult('', ShareResultStatus.dismissed);
        when(
          () => mockSharePlatform.share(any()),
        ).thenAnswer((_) async => expectedResult);

        final testFile = XFile.fromData(
          Uint8List.fromList([1, 2]),
          name: 'test.png',
        );
        await service.shareXFiles(files: [testFile]);

        final captured =
            verify(() => mockSharePlatform.share(captureAny())).captured.single
                as ShareParams;
        check(
          captured.sharePositionOrigin,
        ).equals(ShareConfig.defaultSharePositionOrigin);
      },
    );
  });

  group('ShareService - shareToX', () {
    test('X (Twitter) 投稿画面を正しく開けること', () async {
      when(
        () => mockUrlLauncherPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      final launched = await service.shareToX(
        text: 'こんにちは世界',
        url: 'https://example.com',
        hashtags: ['#Flutter', 'Dart'],
      );

      check(launched).isTrue();

      final captured = verify(
        () => mockUrlLauncherPlatform.launchUrl(captureAny(), captureAny()),
      ).captured;

      final url = captured[0] as String;
      final uri = Uri.parse(url);

      check(uri.scheme).equals('https');
      check(uri.host).equals('twitter.com');
      check(uri.path).equals('/intent/tweet');
      check(uri.queryParameters['text']).equals('こんにちは世界');
      check(uri.queryParameters['url']).equals('https://example.com');
      check(uri.queryParameters['hashtags']).equals('Flutter,Dart');

      check(fakeAppLockService.suppressionCallCount).equals(1);
    });

    test('X (Twitter) 起動に失敗した場合に false を返すこと', () async {
      when(
        () => mockUrlLauncherPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => false);

      final launched = await service.shareToX(text: '失敗テスト');

      check(launched).isFalse();
      check(fakeAppLockService.suppressionCallCount).equals(1);
    });
  });

  group('ShareService - shareToLine', () {
    test('LINE メッセージ送信画面を正しく開けること', () async {
      when(
        () => mockUrlLauncherPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      final launched = await service.shareToLine(text: 'LINEメッセージ');

      check(launched).isTrue();

      final captured = verify(
        () => mockUrlLauncherPlatform.launchUrl(captureAny(), captureAny()),
      ).captured;

      final url = captured[0] as String;
      check(url).startsWith('https://line.me/R/msg/text/?');

      check(fakeAppLockService.suppressionCallCount).equals(1);
    });

    test('LINE 起動に失敗した場合に false を返すこと', () async {
      when(
        () => mockUrlLauncherPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => false);

      final launched = await service.shareToLine(text: 'LINE失敗テスト');

      check(launched).isFalse();
      check(fakeAppLockService.suppressionCallCount).equals(1);
    });
  });

  group('ShareService - createSampleImage', () {
    test('サンプルPNG画像を正常にメモリ上に生成してXFileとして返すこと', () async {
      final file = await service.createSampleImage();

      check(file.mimeType).equals('image/png');
      check(await file.length()).isGreaterThan(0);
    });
  });

  group('shareServiceProvider', () {
    test('ProviderContainer から ShareService が正常に取得できること', () {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(FakeAppLockService.new),
          loggerProvider.overrideWithValue(talker),
        ],
      );
      addTearDown(container.dispose);

      final shareService = container.read(shareServiceProvider);
      check(shareService).isNotNull();
    });
  });
}
