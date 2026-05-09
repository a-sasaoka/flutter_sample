import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---

class MockApiClient extends Mock implements ApiClient {}

class MockCacheManager extends Mock implements CacheManager {}

class MockResponse extends Mock implements Response<List<dynamic>> {}

class MockMapResponse extends Mock implements Response<Map<String, dynamic>> {}

class MockVoidResponse extends Mock implements Response<void> {}

void main() {
  late MockApiClient mockApi;
  late MockCacheManager mockCache;
  late UserRepository repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockCacheManager();

    repository = UserRepository(
      api: mockApi,
      cache: mockCache,
    );
  });

  // テスト用のダミーJSONデータ
  final dummyJson = {
    'id': 1,
    'name': 'Test User 1',
    'email': 'test1@example.com',
    'phone': '123-456-7890',
    'website': 'https://example.com',
    'address': {
      'street': 'Test Street',
      'suite': 'Suite 1',
      'city': 'Tokyo',
      'zipcode': '100-0000',
      'geo': {
        'lat': '35.6895',
        'lng': '139.6917',
      },
    },
  };

  final dummyJsonList = [dummyJson];

  group('UserRepository - fetchUsers', () {
    test('キャッシュが存在する場合、APIは呼ばれずにキャッシュからデータが返されること', () async {
      // Arrange (準備)
      // キャッシュマネージャーがデータ（JSONリスト）を返すように設定
      when(() => mockCache.get('users')).thenAnswer((_) async => dummyJsonList);

      // Act (実行)
      final result = await repository.fetchUsers();

      // Assert (検証)
      expect(result.length, 1);
      expect(result.first.name, 'Test User 1');

      // API通信とキャッシュ保存が「絶対に呼ばれていないこと」を確認
      verifyNever(() => mockApi.get<List<dynamic>>(any()));
      verifyNever(() => mockCache.save(any<String>(), any<dynamic>()));
    });

    test('キャッシュが存在しない場合、APIからデータを取得してキャッシュに保存されること', () async {
      // Arrange (準備)
      // 1. キャッシュマネージャーは null（空）を返す
      when(() => mockCache.get('users')).thenAnswer((_) async => null);

      // 2. APIクライアントは、ダミーデータが入ったレスポンスを返す
      final mockResponse = MockResponse();
      // レスポンスの `.data` が呼ばれたら、ダミーデータを返すように設定
      when(() => mockResponse.data).thenReturn(dummyJsonList);

      // api.get() が呼ばれたら、このモックレスポンスを返す
      when(
        () => mockApi.get<List<dynamic>>('/users'),
      ).thenAnswer((_) async => mockResponse);

      // 3. キャッシュの保存処理（voidなので空のFutureを返す）
      when(
        () => mockCache.save('users', dummyJsonList),
      ).thenAnswer((_) async {});

      // Act (実行)
      final result = await repository.fetchUsers();

      // Assert (検証)
      expect(result.length, 1);
      expect(result.first.name, 'Test User 1');

      // API通信が1回呼ばれ、取得したデータがキャッシュに1回保存されていることを確認
      verify(() => mockApi.get<List<dynamic>>('/users')).called(1);
      verify(() => mockCache.save('users', dummyJsonList)).called(1);
    });

    test('APIからのレスポンスデータが null の場合、空のリストが返され、キャッシュは保存されないこと', () async {
      // Arrange (準備)
      // キャッシュが存在しないように設定
      when(() => mockCache.get('users')).thenAnswer((_) async => null);

      // APIクライアントは、data が null のレスポンスを返す
      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn(null);
      when(
        () => mockApi.get<List<dynamic>>('/users'),
      ).thenAnswer((_) async => mockResponse);

      // Act (実行)
      final result = await repository.fetchUsers();

      // Assert (検証)
      expect(result, isEmpty);

      verify(() => mockApi.get<List<dynamic>>('/users')).called(1);
      verifyNever(() => mockCache.save(any<String>(), any<dynamic>()));
    });

    test('forceRefresh が true の場合、キャッシュを無視してAPIからデータを再取得し、保存すること', () async {
      // Arrange (準備)
      // APIクライアントは正常にレスポンスを返すように設定
      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn(dummyJsonList);
      when(
        () => mockApi.get<List<dynamic>>('/users'),
      ).thenAnswer((_) async => mockResponse);

      when(
        () => mockCache.save('users', dummyJsonList),
      ).thenAnswer((_) async {});

      // Act (実行)
      // 引数に forceRefresh: true を渡す
      final result = await repository.fetchUsers(forceRefresh: true);

      // Assert (検証)
      expect(result.length, 1);
      expect(result.first.name, 'Test User 1');

      verifyNever(() => mockCache.get(any<String>()));

      // API通信が1回呼ばれ、取得したデータがキャッシュに1回保存されていることを確認
      verify(() => mockApi.get<List<dynamic>>('/users')).called(1);
      verify(() => mockCache.save('users', dummyJsonList)).called(1);
    });

    test('API通信でエラーが発生した場合、例外がそのまま投げられ、キャッシュは保存されないこと', () async {
      // Arrange (準備)
      final exception = Exception('API Error');

      // キャッシュは空
      when(() => mockCache.get('users')).thenAnswer((_) async => null);

      // APIが例外を投げる
      when(() => mockApi.get<List<dynamic>>('/users')).thenThrow(exception);

      // Act & Assert (実行と検証)
      // エラーがリポジトリで握りつぶされず、そのまま上位（Notifier）に伝播することを確認
      await expectLater(
        () => repository.fetchUsers(),
        throwsA(exception),
      );

      // エラーが起きたので、キャッシュ保存は絶対に呼ばれていないことを確認
      verifyNever(() => mockCache.save(any<String>(), any<dynamic>()));
    });
  });

  group('UserRepository - CRUD operations', () {
    test('createUser: 正しい引数でPOSTを呼び出し、UserModelを返すこと', () async {
      // Arrange
      final mockResponse = MockMapResponse();
      when(() => mockResponse.data).thenReturn(dummyJson);
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/users',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      final result = await repository.createUser(
        'Test User 1',
        'test1@example.com',
      );

      // Assert
      expect(result.id, 1);
      expect(result.name, 'Test User 1');
      verify(
        () => mockApi.post<Map<String, dynamic>>(
          '/users',
          data: any(
            named: 'data',
            that: isA<Map<String, dynamic>>().having(
              (m) => m['name'],
              'name',
              'Test User 1',
            ),
          ),
        ),
      ).called(1);
    });

    test('updateUserName: 正しいIDとデータでPATCHを呼び出し、更新されたUserModelを返すこと', () async {
      // Arrange
      final updatedJson = {...dummyJson, 'name': 'Updated Name'};
      final mockResponse = MockMapResponse();
      when(() => mockResponse.data).thenReturn(updatedJson);
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          '/users/1',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      final result = await repository.updateUserName(1, 'Updated Name');

      // Assert
      expect(result.id, 1);
      expect(result.name, 'Updated Name');
      verify(
        () => mockApi.patch<Map<String, dynamic>>(
          '/users/1',
          data: {'name': 'Updated Name'},
        ),
      ).called(1);
    });

    test('deleteUser: 正しいIDでDELETEを呼び出すこと', () async {
      // Arrange
      final mockResponse = MockVoidResponse();
      when(
        () => mockApi.delete<void>('/users/1'),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await repository.deleteUser(1);

      // Assert
      verify(() => mockApi.delete<void>('/users/1')).called(1);
    });

    test('createUser: レスポンスデータがnullの場合、例外を投げること', () async {
      // Arrange
      final mockResponse = MockMapResponse();
      when(() => mockResponse.data).thenReturn(null);
      when(
        () =>
            mockApi.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => repository.createUser('Name', 'email@example.com'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to create user'),
          ),
        ),
      );
    });

    test('updateUserName: レスポンスデータがnullの場合、例外を投げること', () async {
      // Arrange
      final mockResponse = MockMapResponse();
      when(() => mockResponse.data).thenReturn(null);
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => repository.updateUserName(1, 'New Name'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to update user'),
          ),
        ),
      );
    });
  });

  group('userRepositoryProvider', () {
    test(
      '依存関係（APIクライアントとキャッシュマネージャー）が正しく注入された UserRepository のインスタンスを提供すること',
      () {
        // 1. Arrange (準備)
        final mockApi = MockApiClient();
        final mockCache = MockCacheManager();

        // 依存する根元のプロバイダーをモックにすり替えたコンテナを作成
        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(mockApi),
            cacheManagerProvider.overrideWithValue(mockCache),
          ],
        );
        addTearDown(container.dispose);

        // 2. Act (実行)
        // テスト対象のプロバイダーを読み込む
        final repository = container.read(userRepositoryProvider);

        // 3. Assert (検証)
        expect(repository, isA<UserRepository>());

        expect(repository.api, equals(mockApi));
        expect(repository.cache, equals(mockCache));
      },
    );
  });
}
