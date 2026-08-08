import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/token_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTokenInterceptor extends Mock implements Interceptor {}

class MockDioInterceptor extends Mock implements InterceptorsWrapper {}

class MockTalker extends Mock implements Talker {
  @override
  TalkerSettings get settings => TalkerSettings();

  @override
  void warning(dynamic message, [Object? exception, StackTrace? stackTrace]) {}
}

void main() {
  late MockTokenInterceptor mockTokenInterceptor;
  late MockDioInterceptor mockDioInterceptor;
  late MockTalker mockTalker;

  setUp(() {
    mockTokenInterceptor = MockTokenInterceptor();
    mockDioInterceptor = MockDioInterceptor();
    mockTalker = MockTalker();
  });

  ProviderContainer createContainer({
    required EnvConfigState config,
    Flavor flavor = Flavor.dev,
  }) {
    final container = ProviderContainer(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        envConfigProvider.overrideWithValue(config),
        authInterceptorsProvider.overrideWithValue([mockTokenInterceptor]),
        tokenInterceptorProvider.overrideWithValue(mockTokenInterceptor),
        dioInterceptorProvider.overrideWithValue(mockDioInterceptor),
        loggerProvider.overrideWithValue(mockTalker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('dioProvider', () {
    test('正しい設定とインターセプター（トークンあり）でDioが生成されること', () {
      const config = EnvConfigState(
        baseUrl: 'https://test.com',
        aiModel: 'test-model',
        connectTimeout: 5,
        receiveTimeout: 10,
        sendTimeout: 5,
        useFirebaseAuth: true,
      );
      final container = createContainer(config: config);

      final dio = container.read(dioProvider);

      // 基本設定の検証
      check(dio.options.baseUrl).equals(config.baseUrl);
      check(dio.options.connectTimeout).equals(const Duration(seconds: 5));
      check(dio.options.receiveTimeout).equals(const Duration(seconds: 10));
      check(dio.options.sendTimeout).equals(const Duration(seconds: 5));
      check(dio.options.headers['Content-Type']).equals('application/json');

      // インターセプターの検証
      final interceptorTypes = dio.interceptors
          .map((i) => i.runtimeType)
          .toList();

      check(interceptorTypes).contains(mockTokenInterceptor.runtimeType);
      check(interceptorTypes).contains(mockDioInterceptor.runtimeType);
      check(interceptorTypes).contains(TalkerDioLogger);
    });

    test(
      'local または dev フレーバーで本番 Functions URL '
      '(.cloudfunctions.net) が設定された場合 StateError がスローされること',
      () {
        const config = EnvConfigState(
          baseUrl: 'https://us-central1-sample.cloudfunctions.net',
          aiModel: 'test-model',
          connectTimeout: 5,
          receiveTimeout: 10,
          sendTimeout: 5,
          useFirebaseAuth: true,
        );

        // local フレーバーでの検証
        final containerLocal = createContainer(
          config: config,
          flavor: Flavor.local,
        );
        check(
          () => containerLocal.read(dioProvider),
        ).throws<Object>();

        // dev フレーバーでの検証
        final containerDev = createContainer(
          config: config,
        );
        check(
          () => containerDev.read(dioProvider),
        ).throws<Object>();

        // 大文字ホスト名 (CLOUDFUNCTIONS.NET) での検証
        const uppercaseConfig = EnvConfigState(
          baseUrl: 'HTTPS://US-CENTRAL1-SAMPLE.CLOUDFUNCTIONS.NET',
          aiModel: 'test-model',
          connectTimeout: 5,
          receiveTimeout: 10,
          sendTimeout: 5,
          useFirebaseAuth: true,
        );
        final containerUppercase = createContainer(
          config: uppercaseConfig,
        );
        check(
          () => containerUppercase.read(dioProvider),
        ).throws<Object>();
      },
    );

    test(
      'stg フレーバーで本番 Functions URL '
      '(.cloudfunctions.net) が設定された場合 警告ログが出力され正常生成されること',
      () {
        const config = EnvConfigState(
          baseUrl: 'https://us-central1-sample.cloudfunctions.net',
          aiModel: 'test-model',
          connectTimeout: 5,
          receiveTimeout: 10,
          sendTimeout: 5,
          useFirebaseAuth: true,
        );

        final containerStg = createContainer(
          config: config,
          flavor: Flavor.stg,
        );
        final dio = containerStg.read(dioProvider);

        check(dio.options.baseUrl).equals(config.baseUrl);
      },
    );
  });

  group('baseDioProvider', () {
    test('正しい設定とインターセプター（トークンなし）でDioが生成されること', () {
      const config = EnvConfigState(
        baseUrl: 'https://base.com',
        aiModel: 'test-model',
        connectTimeout: 3,
        receiveTimeout: 3,
        sendTimeout: 3,
        useFirebaseAuth: true,
      );
      final container = createContainer(config: config);

      final dio = container.read(baseDioProvider);

      // 基本設定の検証
      check(dio.options.baseUrl).equals(config.baseUrl);
      check(dio.options.connectTimeout).equals(const Duration(seconds: 3));

      // インターセプターの検証
      final interceptorTypes = dio.interceptors
          .map((i) => i.runtimeType)
          .toList();

      // トークンインターセプターが含まれていないこと
      check(
        interceptorTypes,
      ).legacyMatcher(isNot(contains(mockTokenInterceptor.runtimeType)));
      // 共通インターセプターとロガーは含まれていること
      check(interceptorTypes).contains(mockDioInterceptor.runtimeType);
      check(interceptorTypes).contains(TalkerDioLogger);
    });
  });

  group('authInterceptorsProvider', () {
    test('デフォルトの動作: オーバーライドしない場合は空のリストを返すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final interceptors = container.read(authInterceptorsProvider);

      check(interceptors).isEmpty();
    });
  });
}
