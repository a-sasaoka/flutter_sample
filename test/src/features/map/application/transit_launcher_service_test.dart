import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/application/transit_launcher_service.dart';
import 'package:flutter_sample/src/features/map/domain/map_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncherPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class MockTalker extends Mock implements Talker {}

void main() {
  late UrlLauncherPlatform originalPlatform;
  late MockUrlLauncherPlatform mockUrlLauncherPlatform;
  late MockTalker mockLogger;
  late TransitLauncherService service;
  var lockSuppressionCallCount = 0;

  Future<T> testLockSuppressionRunner<T>(Future<T> Function() action) async {
    lockSuppressionCallCount++;
    return await action();
  }

  const origin = LatLng(35.681236, 139.767125);
  const destination = LatLng(35.658581, 139.745433);

  setUpAll(() {
    originalPlatform = UrlLauncherPlatform.instance;
    registerFallbackValue(const LaunchOptions());
    registerFallbackValue(StackTrace.empty);
  });

  tearDownAll(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  setUp(() {
    mockUrlLauncherPlatform = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncherPlatform;

    mockLogger = MockTalker();
    lockSuppressionCallCount = 0;

    service = TransitLauncherService(
      lockSuppressionRunner: testLockSuppressionRunner,
      logger: mockLogger,
    );
  });

  group('TransitLauncherService Tests', () {
    test('buildGoogleMapsTransitUri で目的地名称がある場合、名称が destination に指定されること', () {
      final uri = service.buildGoogleMapsTransitUri(
        origin: origin,
        destination: destination,
        destinationName: '東京タワー',
      );

      check(uri.scheme).equals('https');
      check(uri.host).equals(MapConstants.googleMapsHost);
      check(uri.path).equals(MapConstants.googleMapsDirectionsPath);
      check(uri.queryParameters[MapConstants.googleMapsParamApi]).equals('1');
      check(
        uri.queryParameters[MapConstants.googleMapsParamOrigin],
      ).equals('35.681236,139.767125');
      check(
        uri.queryParameters[MapConstants.googleMapsParamDestination],
      ).equals('東京タワー');
      check(
        uri.queryParameters[MapConstants.googleMapsParamTravelMode],
      ).equals('transit');
    });

    test('buildGoogleMapsTransitUri で目的地名称が null または空白の場合、座標が使われること', () {
      final uriNull = service.buildGoogleMapsTransitUri(
        origin: origin,
        destination: destination,
      );
      check(
        uriNull.queryParameters[MapConstants.googleMapsParamDestination],
      ).equals('35.658581,139.745433');

      final uriBlank = service.buildGoogleMapsTransitUri(
        origin: origin,
        destination: destination,
        destinationName: '   ',
      );
      check(
        uriBlank.queryParameters[MapConstants.googleMapsParamDestination],
      ).equals('35.658581,139.745433');
    });

    test('launchTransitRoute で起動が成功した場合 true を返し、誤ロック抑止を実行すること', () async {
      when(
        () => mockUrlLauncherPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      final result = await service.launchTransitRoute(
        origin: origin,
        destination: destination,
        destinationName: '東京タワー',
      );

      check(result).isTrue();
      check(lockSuppressionCallCount).equals(1);
      verify(
        () => mockUrlLauncherPlatform.launchUrl(
          any(
            that: contains(
              'destination=%E6%9D%B1%E4%BA%AC%E3%82%BF%E3%83%AF%E3%83%BC',
            ),
          ),
          any(),
        ),
      ).called(1);
    });

    test('launchTransitRoute で起動が失敗（false）した場合、警告ログを出力し false を返すこと', () async {
      when(
        () => mockUrlLauncherPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => false);

      final result = await service.launchTransitRoute(
        origin: origin,
        destination: destination,
      );

      check(result).isFalse();
      verify(() => mockLogger.warning(any<String>())).called(1);
    });

    test('launchTransitRoute で例外が発生した場合、エラーログを記録し false を返すこと', () async {
      when(() => mockUrlLauncherPlatform.launchUrl(any(), any())).thenThrow(
        PlatformException(code: 'ACTIVITY_NOT_FOUND', message: 'No app'),
      );

      final result = await service.launchTransitRoute(
        origin: origin,
        destination: destination,
      );

      check(result).isFalse();
      verify(
        () =>
            mockLogger.handle(any<Object>(), any<StackTrace>(), any<String>()),
      ).called(1);
    });

    test('transitLauncherServiceProvider からインスタンスを正常に取得できること', () {
      final container = ProviderContainer(
        overrides: [loggerProvider.overrideWithValue(mockLogger)],
      );
      addTearDown(container.dispose);

      final providerService = container.read(transitLauncherServiceProvider);
      check(providerService).isA<TransitLauncherService>();
    });
  });
}
