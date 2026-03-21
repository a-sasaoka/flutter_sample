import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// モッククラスを定義
// mocktail の Mock を継承し、対象のインターフェースを implements します
class MockApiClient extends Mock implements ApiClient {}

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  late MockApiClient mockApiClient;
  late MockCacheManager mockCacheManager;
  late ProviderContainer container;

  // 各テスト（test）が走る「直前」に毎回呼ばれる初期化処理
  setUp(() {
    mockApiClient = MockApiClient();
    mockCacheManager = MockCacheManager();

    // プロバイダーの値をモックに差し替えたコンテナを作成（DIの真骨頂！）
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockApiClient),
        cacheManagerProvider.overrideWithValue(mockCacheManager),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // テストで使い回すダミーのJSONデータ
  final mockUserJson = [
    {
      'id': 1,
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '1234567890',
      'website': 'example.com',
      'address': {
        'street': '123 Main St',
        'suite': 'Apt 456',
        'city': 'Cityville',
        'zipcode': '12345',
        'geo': {
          'lat': '40.7128',
          'lng': '-74.0060',
        },
      },
    },
  ];

  group('UserRepository.fetchUsers テスト', () {
    test('キャッシュが存在する場合、APIを叩かずにキャッシュからユーザー一覧を返すこと', () async {
      // Arrange (準備)
      // キャッシュからダミーデータが返ってくるようにモックを設定
      when(
        () => mockCacheManager.get('users'),
      ).thenAnswer((_) async => mockUserJson);

      // Act (実行):
      // メソッドを呼び出す
      final repository = container.read(userRepositoryProvider.notifier);
      final users = await repository.fetchUsers();

      // Assert (検証)
      expect(users.length, 1);
      expect(users.first.name, 'John Doe');

      // キャッシュの取得メソッドが1回呼ばれたことを検証
      verify(() => mockCacheManager.get('users')).called(1);
      // API通信が「絶対に呼ばれていないこと」を確認
      verifyNever(() => mockApiClient.get<dynamic>(any()));
    });

    test('キャッシュが存在しない場合、APIから取得してキャッシュに保存し、ユーザーを返すこと', () async {
      // Arrange (準備)
      // キャッシュからは「null（データなし）」が返るように設定
      when(() => mockCacheManager.get('users')).thenAnswer((_) async => null);
      // キャッシュの保存処理が呼ばれたら、何もせずに完了するように設定
      when(
        () => mockCacheManager.save('users', mockUserJson),
      ).thenAnswer((_) async {});
      // API通信が呼ばれたら、200 OK でダミーデータを返すように設定
      when(() => mockApiClient.get<List<dynamic>>('/users')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/users'),
          data: mockUserJson,
          statusCode: 200,
        ),
      );

      // Act (実行)
      final repository = container.read(userRepositoryProvider.notifier);
      final users = await repository.fetchUsers();

      // Assert (検証)
      expect(users.length, 1);

      // それぞれのメソッドが正しい順番・回数で呼ばれたことを検証
      verify(() => mockCacheManager.get('users')).called(1);
      verify(() => mockApiClient.get<List<dynamic>>('/users')).called(1);
      verify(() => mockCacheManager.save('users', mockUserJson)).called(1);
    });
  });
}
