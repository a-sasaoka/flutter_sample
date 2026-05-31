import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モックの定義 ---

class MockApiClient extends Mock implements ApiClient {}

class MockCacheManager extends Mock implements CacheManager {}

class MockTalker extends Mock implements Talker {}

class MockResponse extends Mock implements Response<List<dynamic>> {}

class MockMapResponse extends Mock implements Response<Map<String, dynamic>> {}

class MockVoidResponse extends Mock implements Response<void> {}

void main() {
  late MockApiClient mockApi;
  late MockCacheManager mockCache;
  late MockTalker mockTalker;
  late UserRepository repository;

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockCacheManager();
    mockTalker = MockTalker();

    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.error(any<dynamic>())).thenReturn(null);

    repository = UserRepository(
      api: mockApi,
      cache: mockCache,
      talker: mockTalker,
      clock: () => DateTime(2026, 5, 17, 10),
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
  final dummyTimestamp = DateTime(2026, 5, 17, 9);

  group('UserRepository - fetchUsers', () {
    test('キャッシュが存在する場合、APIは呼ばれずにキャッシュからデータが返されること', () async {
      // Arrange (準備)
      // キャッシュマネージャーがデータ（JSONリスト）とタイムスタンプを1回で返すように設定
      when(
        () => mockCache.getWithTimestamp('users'),
      ).thenAnswer((_) async => (dummyJsonList, dummyTimestamp));

      // Act (実行)
      final (users, fetchedAt) = await repository.fetchUsers();

      // Assert (検証)
      check(users.length).equals(1);
      check(users.first.name).equals('Test User 1');
      check(fetchedAt).equals(dummyTimestamp);

      // API通信とキャッシュ保存が「絶対に呼ばれていないこと」を確認
      verifyNever(() => mockApi.get<List<dynamic>>(any()));
      verifyNever(() => mockCache.save(any<String>(), any<dynamic>()));
    });

    test('キャッシュデータは存在するが、タイムスタンプが null の場合、現在時刻が返されること', () async {
      // Arrange (準備)
      // データはあるがタイムスタンプが null という状況をモックで再現
      when(
        () => mockCache.getWithTimestamp('users'),
      ).thenAnswer((_) async => (dummyJsonList, null));

      // Act (実行)
      final (users, fetchedAt) = await repository.fetchUsers();

      // Assert (検証)
      check(users.length).equals(1);
      // clock() で設定している 10:00 が返ることを確認
      check(fetchedAt).equals(DateTime(2026, 5, 17, 10));
    });

    test('キャッシュが存在しない場合、APIからデータを取得してキャッシュに保存されること', () async {
      // Arrange (準備)
      // 1. キャッシュマネージャーは (null, null) を返す
      when(
        () => mockCache.getWithTimestamp('users'),
      ).thenAnswer((_) async => (null, null));

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
      final (users, fetchedAt) = await repository.fetchUsers();

      // Assert (検証)
      check(users.length).equals(1);
      check(users.first.name).equals('Test User 1');
      check(fetchedAt).equals(DateTime(2026, 5, 17, 10));

      // API通信が1回呼ばれ、取得したデータがキャッシュに1回保存されていることを確認
      verify(() => mockApi.get<List<dynamic>>('/users')).called(1);
      verify(() => mockCache.save('users', dummyJsonList)).called(1);
    });

    test('APIからのレスポンスデータが null の場合、空のリストが返され、キャッシュは保存されないこと', () async {
      // Arrange (準備)
      // キャッシュが存在しないように設定
      when(
        () => mockCache.getWithTimestamp('users'),
      ).thenAnswer((_) async => (null, null));

      // APIクライアントは、data が null のレスポンスを返す
      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn(null);
      when(
        () => mockApi.get<List<dynamic>>('/users'),
      ).thenAnswer((_) async => mockResponse);

      // Act (実行)
      final (users, _) = await repository.fetchUsers();

      // Assert (検証)
      check(users).isEmpty();

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
      final (users, fetchedAt) = await repository.fetchUsers(
        forceRefresh: true,
      );

      // Assert (検証)
      check(users.length).equals(1);
      check(users.first.name).equals('Test User 1');
      check(fetchedAt).equals(DateTime(2026, 5, 17, 10));

      verifyNever(() => mockCache.getWithTimestamp(any<String>()));

      // API通信が1回呼ばれ、取得したデータがキャッシュに1回保存されていることを確認
      verify(() => mockApi.get<List<dynamic>>('/users')).called(1);
      verify(() => mockCache.save('users', dummyJsonList)).called(1);
    });

    test('API通信でエラーが発生した場合、例外がそのまま投げられ、キャッシュは保存されないこと', () async {
      // Arrange (準備)
      final exception = Exception('API Error');

      // キャッシュは空
      when(
        () => mockCache.getWithTimestamp('users'),
      ).thenAnswer((_) async => (null, null));

      // APIが例外を投げる
      when(() => mockApi.get<List<dynamic>>('/users')).thenThrow(exception);

      // Act & Assert (実行と検証)
      // エラーがリポジトリで握りつぶされず、そのまま上位（Notifier）に伝播することを確認
      try {
        await repository.fetchUsers();
        fail('Exception not thrown');
      } on Exception catch (e) {
        check(e).equals(exception);
      }

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

      // 💡 キャッシュクリアをスタブ化
      when(() => mockCache.clear(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.createUser(
        'Test User 1',
        'test1@example.com',
      );

      // Assert
      check(result.id).equals(1);
      check(result.name).equals('Test User 1');
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
      // キャッシュがクリアされたことを確認
      verify(() => mockCache.clear('users')).called(1);
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

      // 💡 キャッシュクリアをスタブ化
      when(() => mockCache.clear(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.updateUserName(1, 'Updated Name');

      // Assert
      check(result.id).equals(1);
      check(result.name).equals('Updated Name');
      verify(
        () => mockApi.patch<Map<String, dynamic>>(
          '/users/1',
          data: {'name': 'Updated Name'},
        ),
      ).called(1);
      // キャッシュがクリアされたことを確認
      verify(() => mockCache.clear('users')).called(1);
    });

    test('deleteUser: 正しいIDでDELETEを呼び出すこと', () async {
      // Arrange
      final mockResponse = MockVoidResponse();
      when(
        () => mockApi.delete<void>('/users/1'),
      ).thenAnswer((_) async => mockResponse);

      // 💡 キャッシュクリアをスタブ化
      when(() => mockCache.clear(any())).thenAnswer((_) async {});

      // Act
      await repository.deleteUser(1);

      // Assert
      verify(() => mockApi.delete<void>('/users/1')).called(1);
      // キャッシュがクリアされたことを確認
      verify(() => mockCache.clear('users')).called(1);
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
      check(
        () => repository.createUser('Name', 'email@example.com'),
      ).legacyMatcher(
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
      check(() => repository.updateUserName(1, 'New Name')).legacyMatcher(
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
      '依存関係（APIクライアントとキャッシュマネージャー）が正しく注入された '
      'UserRepository のインスタンスを提供すること',
      () {
        // 1. Arrange (準備)
        final mockApi = MockApiClient();
        final mockCache = MockCacheManager();

        // 依存する根元のプロバイダーをモックにすり替えたコンテナを作成
        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(mockApi),
            cacheManagerProvider.overrideWithValue(mockCache),
            loggerProvider.overrideWithValue(mockTalker),
            clockProvider.overrideWithValue(DateTime.now),
          ],
        );
        addTearDown(container.dispose);

        // 2. Act (実行)
        // テスト対象のプロバイダーを読み込む
        final repository = container.read(userRepositoryProvider);

        // 3. Assert (検証)
        check(repository).isA<UserRepository>();

        check(repository.api).equals(mockApi);
        check(repository.cache).equals(mockCache);
      },
    );
  });
}
