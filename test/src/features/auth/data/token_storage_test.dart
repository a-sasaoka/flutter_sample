import 'package:checks/checks.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// FlutterSecureStorage のモック
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TokenStorage', () {
    const testAccessToken = 'test_access_token';
    const testRefreshToken = 'test_refresh_token';

    test('saveTokens: アクセストークンとリフレッシュトークンを正しいキーで保存すること', () async {
      // Arrange
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      // Act
      await storage.saveTokens(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
      );

      // Assert
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: testAccessToken,
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: testRefreshToken,
        ),
      ).called(1);
    });

    test('getAccessToken: 保存されているアクセストークンを取得できること', () async {
      // Arrange
      when(
        () => mockStorage.read(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async => testAccessToken);
      final storage = container.read(tokenStorageProvider);

      // Act
      final result = await storage.getAccessToken();

      // Assert
      check(result).equals(testAccessToken);
      verify(
        () => mockStorage.read(key: SecureStorageKeys.accessToken),
      ).called(1);
    });

    test('getRefreshToken: 保存されているリフレッシュトークンを取得できること', () async {
      // Arrange
      when(
        () => mockStorage.read(key: SecureStorageKeys.refreshToken),
      ).thenAnswer((_) async => testRefreshToken);
      final storage = container.read(tokenStorageProvider);

      // Act
      final result = await storage.getRefreshToken();

      // Assert
      check(result).equals(testRefreshToken);
      verify(
        () => mockStorage.read(key: SecureStorageKeys.refreshToken),
      ).called(1);
    });

    test('clear: 両方のトークンを削除すること', () async {
      // Arrange
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      // Act
      await storage.clear();

      // Assert
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).called(1);
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      ).called(1);
    });

    test('トークンが保存されていない場合、get メソッドが null を返すこと', () async {
      // Arrange
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      final storage = container.read(tokenStorageProvider);

      // Act
      final access = await storage.getAccessToken();
      final refresh = await storage.getRefreshToken();

      // Assert
      check(access).isNull();
      check(refresh).isNull();
    });
  });

  group('TokenStorage ユニットテスト (Providerなし)', () {
    test('DIにより、ProviderContainerなしでも単体テストが可能なこと', () async {
      // Arrange
      final mockStorage = MockFlutterSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'raw_token');

      final storage = TokenStorage(secureStorage: mockStorage);

      // Act
      final token = await storage.getAccessToken();

      // Assert
      check(token).equals('raw_token');
      verify(
        () => mockStorage.read(key: SecureStorageKeys.accessToken),
      ).called(1);
    });
  });
}
