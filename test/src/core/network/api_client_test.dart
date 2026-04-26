import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

// モッククラス
class MockDio extends Mock implements Dio {}

class MockTokenInterceptor extends Mock implements InterceptorsWrapper {}

class MockDioInterceptor extends Mock implements InterceptorsWrapper {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUp(() {
    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [
        // dioProvider が返すインスタンスをモックに差し替え
        dioProvider.overrideWithValue(mockDio),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ApiClient テスト', () {
    test('get() が正しいパスとパラメータで dio.get を呼び出すこと', () async {
      // Arrange
      const path = '/test-path';
      final queryParams = {'id': 123};
      final mockResponse = Response(
        requestOptions: RequestOptions(path: path),
        data: {'success': true},
        statusCode: 200,
      );

      // stub: dio.get が呼ばれたら mockResponse を返すように設定
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final client = container.read(apiClientProvider);

      // Act
      final result = await client.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParams,
      );

      // Assert
      expect(result.data, equals({'success': true}));
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          path,
          queryParameters: queryParams,
        ),
      ).called(1);
    });

    test('post() が正しいパスとデータで dio.post を呼び出すこと', () async {
      // Arrange
      const path = '/post-path';
      final postData = {'name': 'test'};
      final mockResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: 201,
      );

      when(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final client = container.read(apiClientProvider);

      // Act
      await client.post<dynamic>(path, data: postData);

      // Assert
      verify(
        () => mockDio.post<dynamic>(
          path,
          data: postData,
        ),
      ).called(1);
    });

    test('put() が正しく呼び出されること', () async {
      const path = '/put-path';
      when(
        () => mockDio.put<dynamic>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: path)),
      );

      await container
          .read(apiClientProvider)
          .put<dynamic>(path, data: {'key': 'val'});

      verify(() => mockDio.put<dynamic>(path, data: {'key': 'val'})).called(1);
    });

    test('delete() が正しく呼び出されること', () async {
      const path = '/delete-path';
      when(
        () => mockDio.delete<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: path)),
      );

      await container.read(apiClientProvider).delete<dynamic>(path);

      verify(() => mockDio.delete<dynamic>(path)).called(1);
    });
  });

  group('dioProvider 設定テスト', () {
    test('dioProvider が正しい BaseOptions と Interceptor で構成されていること', () {
      final mockTokenInterceptor = MockTokenInterceptor();
      final mockDioInterceptor = MockDioInterceptor();
      final mockTalker = MockTalker();

      // TalkerDioLogger が内部で talker.settings を参照するため、スタブ化して null エラーを防ぐ
      when(() => mockTalker.settings).thenReturn(TalkerSettings());

      final testContainer = ProviderContainer(
        overrides: [
          tokenInterceptorProvider.overrideWithValue(mockTokenInterceptor),
          dioInterceptorProvider.overrideWithValue(mockDioInterceptor),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );

      final dio = testContainer.read(dioProvider);

      expect(dio.options.baseUrl, isNotEmpty);
      expect(dio.options.connectTimeout, isNotNull);
      expect(dio.options.receiveTimeout, isNotNull);
      expect(dio.options.sendTimeout, isNotNull);
      expect(dio.options.headers['Content-Type'], equals('application/json'));

      // runtimeType を使って、期待するインターセプターが含まれているか確認
      final interceptorTypes = dio.interceptors
          .map((i) => i.runtimeType)
          .toList();

      expect(interceptorTypes[1], equals(MockTokenInterceptor));
      expect(interceptorTypes[2], equals(MockDioInterceptor));
      expect(interceptorTypes[3], equals(TalkerDioLogger));

      testContainer.dispose();
    });
  });
}
