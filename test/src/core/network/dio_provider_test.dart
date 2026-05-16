import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTokenInterceptor extends Mock implements Interceptor {}

class MockDioInterceptor extends Mock implements InterceptorsWrapper {}

class MockTalker extends Mock implements Talker {
  @override
  TalkerSettings get settings => TalkerSettings();
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
  }) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(config),
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
      expect(dio.options.baseUrl, equals(config.baseUrl));
      expect(dio.options.connectTimeout, equals(const Duration(seconds: 5)));
      expect(dio.options.receiveTimeout, equals(const Duration(seconds: 10)));
      expect(dio.options.sendTimeout, equals(const Duration(seconds: 5)));
      expect(dio.options.headers['Content-Type'], equals('application/json'));

      // インターセプターの検証
      final interceptorTypes = dio.interceptors
          .map((i) => i.runtimeType)
          .toList();

      expect(interceptorTypes, contains(mockTokenInterceptor.runtimeType));
      expect(interceptorTypes, contains(mockDioInterceptor.runtimeType));
      expect(interceptorTypes, contains(TalkerDioLogger));
    });
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
      expect(dio.options.baseUrl, equals(config.baseUrl));
      expect(dio.options.connectTimeout, equals(const Duration(seconds: 3)));

      // インターセプターの検証
      final interceptorTypes = dio.interceptors
          .map((i) => i.runtimeType)
          .toList();

      // トークンインターセプターが含まれていないこと
      expect(
        interceptorTypes,
        isNot(contains(mockTokenInterceptor.runtimeType)),
      );
      // 共通インターセプターとロガーは含まれていること
      expect(interceptorTypes, contains(mockDioInterceptor.runtimeType));
      expect(interceptorTypes, contains(TalkerDioLogger));
    });
  });
}
