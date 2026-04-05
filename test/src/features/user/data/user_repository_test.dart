import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---

class MockApiClient extends Mock implements ApiClient {}

class MockCacheManager extends Mock implements CacheManager {}

class MockResponse extends Mock implements Response<List<dynamic>> {}

void main() {
  late MockApiClient mockApi;
  late MockCacheManager mockCache;
  late UserRepository repository;

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockCacheManager();

    repository = UserRepository(
      api: mockApi,
      cache: mockCache,
    );
  });

  // テスト用のダミーJSONデータ
  final dummyJsonList = [
    {
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
    },
  ];

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

  group('userRepositoryProvider', () {
    test(
      '依存関係（APIクライアントとキャッシュマネージャー）が正しく注入された UserRepository のインスタンスを提供すること',
      () {
        // 1. Arrange (準備)
        final mockApi = MockApiClient();
        final mockCache = MockCacheManager();

        // 💡 依存する根元のプロバイダーをモックにすり替えたコンテナを作成
        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(mockApi),
            cacheManagerProvider.overrideWithValue(mockCache),
          ],
        );
        addTearDown(container.dispose);

        // 2. Act (実行)
        // 💡 テスト対象のプロバイダーを読み込む
        final repository = container.read(userRepositoryProvider);

        // 3. Assert (検証)
        // ① 正しく UserRepository のインスタンスが生成されているか
        expect(repository, isA<UserRepository>());

        // ② コンストラクタ経由で注入されたプロパティが、私たちが用意したモックと「完全に同一のインスタンス」であるか
        expect(repository.api, equals(mockApi));
        expect(repository.cache, equals(mockCache));
      },
    );
  });
}
