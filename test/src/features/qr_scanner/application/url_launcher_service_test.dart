import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncherPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class MockAppLockService extends Mock implements AppLockService {}

class FakeAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() async => const AppLockState.disabled();
}

void main() {
  late UrlLauncherPlatform originalPlatform;

  setUpAll(() {
    originalPlatform = UrlLauncherPlatform.instance;
    registerFallbackValue(const LaunchOptions());
  });

  tearDownAll(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  group('UrlLauncherService', () {
    late UrlLauncherService service;
    late MockAppLockService mockAppLockService;

    setUp(() {
      mockAppLockService = MockAppLockService();
      when(
        () => mockAppLockService.runWithLockSuppression<bool>(any()),
      ).thenAnswer((invocation) async {
        final action =
            invocation.positionalArguments[0] as Future<bool> Function();
        return await action();
      });
      service = UrlLauncherService(appLockService: mockAppLockService);
    });

    test('http または https の URL を正しく Web URL と判定できること', () {
      check(service.isWebUrl('https://example.com')).equals(true);
      check(service.isWebUrl('http://example.com/test?param=1')).equals(true);
      check(service.isWebUrl('  https://example.com  ')).equals(true);
    });

    test('Web URL ではない文字列（スキームなし、mailto、プレーンテキスト）を拒否すること', () {
      check(service.isWebUrl('example.com')).equals(false);
      check(service.isWebUrl('mailto:test@example.com')).equals(false);
      check(service.isWebUrl('plain text')).equals(false);
      check(service.isWebUrl('')).equals(false);
    });

    test('ホスト名やオーソリティが存在しない不完全なURL (https:, https:/path) を拒否すること', () {
      check(service.isWebUrl('https:')).equals(false);
      check(service.isWebUrl('https:/path')).equals(false);
      check(service.isWebUrl('http:')).equals(false);
      check(service.isWebUrl('http:/path')).equals(false);
    });

    test('無効な URL の場合 openUrl は false を返し launchUrl を呼ばないこと', () async {
      final mockPlatform = MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = mockPlatform;

      check(await service.openUrl('not a valid url ::: //')).equals(false);
      check(await service.openUrl('https:')).equals(false);
      check(await service.openUrl('https:/path')).equals(false);
      verifyNever(() => mockPlatform.launchUrl(any(), any()));
    });

    test('有効な URL の場合 launchUrl を呼び出して結果を返すこと', () async {
      final mockPlatform = MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = mockPlatform;

      when(
        () => mockPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      final result = await service.openUrl('https://example.com');
      check(result).equals(true);
      verify(
        () => mockPlatform.launchUrl('https://example.com', any()),
      ).called(1);
    });

    test('appLockService 注入時に runWithLockSuppression を呼ぶこと', () async {
      final mockPlatform = MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = mockPlatform;
      final mockAppLockService = MockAppLockService();
      final serviceWithLock = UrlLauncherService(
        appLockService: mockAppLockService,
      );

      when(
        () => mockPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockAppLockService.runWithLockSuppression<bool>(any()),
      ).thenAnswer((invocation) async {
        final action =
            invocation.positionalArguments[0] as Future<bool> Function();
        return await action();
      });

      final result = await serviceWithLock.openUrl('https://example.com');
      check(result).equals(true);
      verify(
        () => mockAppLockService.runWithLockSuppression<bool>(any()),
      ).called(1);
      verify(
        () => mockPlatform.launchUrl('https://example.com', any()),
      ).called(1);
    });

    test('urlLauncherServiceProvider からインスタンスが取得できること', () {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(FakeAppLockService.new),
        ],
      );
      addTearDown(container.dispose);

      final providerService = container.read(urlLauncherServiceProvider);
      check(providerService).isA<UrlLauncherService>();
    });
  });
}
