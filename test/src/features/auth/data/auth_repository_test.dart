import 'package:dio/dio.dart'; // Responseクラス用
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart'; // パスは適宜合わせてください
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとFakeクラスの定義 ---

// ApiClientのモック
class MockApiClient extends Mock implements ApiClient {}

// DioのResponseのモック
class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

// TokenStorageのモック
class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({this.initialRefreshToken});

  final String? initialRefreshToken;

  // 保存された値を検証するためのプロパティ
  String? savedAccessToken;
  String? savedRefreshToken;

  @override
  Future<String?> getRefreshToken() async => initialRefreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    savedAccessToken = accessToken;
    savedRefreshToken = refreshToken;
  }
}

void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
  });

  /// 依存関係を注入した ProviderContainer を作成するヘルパー
  ProviderContainer createContainer(FakeTokenStorage fakeStorage) {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockApi),
        // 💡 修正: tokenStorageProvider は Notifier ではないので (ref) => の形でオーバーライドする
        tokenStorageProvider.overrideWith((ref) => fakeStorage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthRepository', () {
    test('login: APIを呼び出し、取得したトークンをTokenStorageに保存すること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      // APIが返すダミーのレスポンスデータを設定
      when(() => mockResponse.data).thenReturn({
        'access_token': 'new_access_token',
        'refresh_token': 'new_refresh_token',
      });
      // postメソッドが呼ばれたらモックレスポンスを返す
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await repo.login('test@example.com', 'password123');

      // Assert
      // 1. APIが正しい引数で呼ばれたか
      // Mapの比較はそのまま書くとインスタンス違いで失敗するため、equals() を使用する
      verify(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(
            named: 'data',
            that: equals({
              'email': 'test@example.com',
              'password': 'password123',
            }),
          ),
        ),
      ).called(1);

      // 2. TokenStorageに正しい値が保存されたか
      expect(fakeStorage.savedAccessToken, 'new_access_token');
      expect(fakeStorage.savedRefreshToken, 'new_refresh_token');
    });

    test('login: APIレスポンスにトークンが含まれていない場合、Exceptionを投げること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      // access_token が欠落している不正なレスポンスをシミュレート
      when(() => mockResponse.data).thenReturn({
        'refresh_token': 'new_refresh_token', // access_tokenがない
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act & Assert
      await expectLater(
        () => repo.login('test@example.com', 'password123'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid token response from server'),
          ),
        ),
      );

      // 例外が発生し、TokenStorageに保存処理が行われていないことを確認
      expect(fakeStorage.savedAccessToken, isNull);
    });

    group('refreshToken', () {
      test('TokenStorageにリフレッシュトークンがない場合、APIを呼ばずに false を返すこと', () async {
        // Arrange: 初期リフレッシュトークンを null に設定
        final fakeStorage = FakeTokenStorage();
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        // Act
        final result = await repo.refreshToken();

        // Assert
        expect(result, isFalse);
        // APIが一切呼ばれていないことを確認
        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any<dynamic>(named: 'data'),
          ),
        );
      });

      test('APIのレスポンスに access_token が含まれていない場合、保存せずに false を返すこと', () async {
        // Arrange
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'old_refresh',
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final mockResponse = MockResponse();
        // access_token が null (または存在しない) レスポンスをシミュレート
        when(() => mockResponse.data).thenReturn({'access_token': null});

        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repo.refreshToken();

        // Assert
        expect(result, isFalse);
        // 保存処理が呼ばれていない（プロパティがnullのまま）ことを確認
        expect(fakeStorage.savedAccessToken, isNull);
      });

      test('APIから新しいアクセストークンを取得できた場合、保存して true を返すこと', () async {
        // Arrange
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'valid_refresh',
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final mockResponse = MockResponse();
        when(
          () => mockResponse.data,
        ).thenReturn({'access_token': 'refreshed_access'});

        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repo.refreshToken();

        // Assert
        expect(result, isTrue);

        // APIが正しいリフレッシュトークンを送信したか
        verify(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(
              named: 'data',
              that: equals({'refresh_token': 'valid_refresh'}),
            ),
          ),
        ).called(1);

        // 新しいアクセストークンと、既存のリフレッシュトークンが保存されたか
        expect(fakeStorage.savedAccessToken, 'refreshed_access');
        expect(fakeStorage.savedRefreshToken, 'valid_refresh');
      });
    });
  });

  group('authRepositoryProvider', () {
    test(
      '依存関係（APIクライアントとトークンストレージ）が正しく注入された AuthRepository のインスタンスを提供すること',
      () {
        // 1. Arrange (準備)
        final fakeStorage = FakeTokenStorage();

        // 依存するプロバイダーをモック・フェイクにすり替えたコンテナを作成
        final container = createContainer(fakeStorage);

        // 2. Act (実行)
        // テスト対象のプロバイダーを読み込む
        final repository = container.read(authRepositoryProvider);

        // 3. Assert (検証)
        expect(repository, isA<AuthRepository>());

        expect(repository.api, equals(mockApi));
        expect(repository.tokenStorage, equals(fakeStorage));
      },
    );
  });
}
