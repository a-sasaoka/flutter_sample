import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesAsync のモック
class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;
  late ProviderContainer container;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    container = ProviderContainer(
      overrides: [
        // sharedPreferencesProvider をモックで上書き
        sharedPreferencesProvider.overrideWith(
          (ref) => Future.value(mockPrefs),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TokenStorage', () {
    const testAccessToken = 'test_access_token';
    const testRefreshToken = 'test_refresh_token';
    const accessTokenKey = 'access_token';
    const refreshTokenKey = 'refresh_token';

    test('saveTokens: アクセストークンとリフレッシュトークンを正しいキーで保存すること', () async {
      // Arrange
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      // Act
      await storage.saveTokens(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
      );

      // Assert
      verify(
        () => mockPrefs.setString(accessTokenKey, testAccessToken),
      ).called(1);
      verify(
        () => mockPrefs.setString(refreshTokenKey, testRefreshToken),
      ).called(1);
    });

    test('getAccessToken: 保存されているアクセストークンを取得できること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(accessTokenKey),
      ).thenAnswer((_) async => testAccessToken);
      final storage = container.read(tokenStorageProvider);

      // Act
      final result = await storage.getAccessToken();

      // Assert
      expect(result, testAccessToken);
      verify(() => mockPrefs.getString(accessTokenKey)).called(1);
    });

    test('getRefreshToken: 保存されているリフレッシュトークンを取得できること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(refreshTokenKey),
      ).thenAnswer((_) async => testRefreshToken);
      final storage = container.read(tokenStorageProvider);

      // Act
      final result = await storage.getRefreshToken();

      // Assert
      expect(result, testRefreshToken);
      verify(() => mockPrefs.getString(refreshTokenKey)).called(1);
    });

    test('clear: 両方のトークンを削除すること', () async {
      // Arrange
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      // Act
      await storage.clear();

      // Assert
      verify(() => mockPrefs.remove(accessTokenKey)).called(1);
      verify(() => mockPrefs.remove(refreshTokenKey)).called(1);
    });

    test('トークンが保存されていない場合、get メソッドが null を返すこと', () async {
      // Arrange
      when(() => mockPrefs.getString(any())).thenAnswer((_) async => null);
      final storage = container.read(tokenStorageProvider);

      // Act
      final access = await storage.getAccessToken();
      final refresh = await storage.getRefreshToken();

      // Assert
      expect(access, isNull);
      expect(refresh, isNull);
    });
  });
}
