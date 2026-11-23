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
      overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TokenStorage', () {
    const testAccessToken = 'test_access_token';
    const testRefreshToken = 'test_refresh_token';

    test('saveTokens: アクセストークンとリフレッシュトークンを正しいキーで保存し、 '
        'subが無い場合は保存済み customUserId を削除すること', () async {
      // Arrange
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});
      when(
        () => mockStorage.delete(key: SecureStorageKeys.customUserId),
      ).thenAnswer((_) async {});
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
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.customUserId),
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

    test('clear: 両方のトークンおよび customUserId を削除すること', () async {
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
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.customUserId),
      ).called(1);
    });

    test('clear: 途中で削除に失敗しても全3キーの削除を試行し、最初のエラーを再スローすること', () async {
      final firstError = Exception('access delete failed');
      final secondError = Exception('refresh delete failed');
      when(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).thenThrow(firstError);
      when(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      ).thenThrow(secondError);
      when(
        () => mockStorage.delete(key: SecureStorageKeys.customUserId),
      ).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      try {
        await storage.clear();
        fail('Exception not thrown');
      } on Exception catch (e) {
        check(e).equals(firstError);
      }

      verify(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).called(1);
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      ).called(1);
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.customUserId),
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
      final userId = await storage.getUserId();

      // Assert
      check(access).isNull();
      check(refresh).isNull();
      check(userId).isNull();
    });

    test('saveTokens: JWTアクセストークンから customUserId を抽出して暗号化保存すること', () async {
      // Arrange
      // 有効なJWT: sub: user_abc123
      const validJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJ1c2VyX2FiYzEyMyJ9.'
          'dummy_signature';
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      // Act
      await storage.saveTokens(
        accessToken: validJwt,
        refreshToken: testRefreshToken,
      );

      // Assert
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: validJwt,
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: testRefreshToken,
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.customUserId,
          value: 'user_abc123',
        ),
      ).called(1);
    });

    test('getUserId: 保存されている customUserId を取得できること', () async {
      // Arrange
      when(
        () => mockStorage.read(key: SecureStorageKeys.customUserId),
      ).thenAnswer((_) async => 'stored_user_id');
      final storage = container.read(tokenStorageProvider);

      // Act
      final result = await storage.getUserId();

      // Assert
      check(result).equals('stored_user_id');
      verify(
        () => mockStorage.read(key: SecureStorageKeys.customUserId),
      ).called(1);
    });

    test('getUserId: customUserIdが未保存でもアクセストークンから復元して保存・返却すること', () async {
      // Arrange
      const validJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJyZWNvdmVyZWRfdXNlciJ9.'
          'dummy_signature';
      when(
        () => mockStorage.read(key: SecureStorageKeys.customUserId),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async => validJwt);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});
      final storage = container.read(tokenStorageProvider);

      // Act
      final result = await storage.getUserId();

      // Assert
      check(result).equals('recovered_user');
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.customUserId,
          value: 'recovered_user',
        ),
      ).called(1);
    });

    test(
      'saveTokens: refreshToken の書込失敗時は書込済みの accessToken を削除して再スローすること',
      () async {
        final writeError = Exception('refresh write failed');
        when(
          () => mockStorage.write(
            key: SecureStorageKeys.accessToken,
            value: testAccessToken,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.write(
            key: SecureStorageKeys.refreshToken,
            value: testRefreshToken,
          ),
        ).thenThrow(writeError);
        when(
          () => mockStorage.delete(key: SecureStorageKeys.accessToken),
        ).thenAnswer((_) async {});
        final storage = container.read(tokenStorageProvider);

        await check(
          storage.saveTokens(
            accessToken: testAccessToken,
            refreshToken: testRefreshToken,
          ),
        ).throws<Exception>((it) => it.equals(writeError));

        verify(
          () => mockStorage.delete(key: SecureStorageKeys.accessToken),
        ).called(1);
        verifyNever(
          () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
        );
        verifyNever(
          () => mockStorage.delete(key: SecureStorageKeys.customUserId),
        );
      },
    );

    test(
      'saveTokens: customUserId 書込失敗時は既書込キーの削除を試行し削除エラーがあっても元例外を再スローすること',
      () async {
        const validJwt =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiJ1c2VyX2FiYzEyMyJ9.'
            'dummy_signature';
        final writeError = Exception('userId write failed');
        when(
          () => mockStorage.write(
            key: SecureStorageKeys.accessToken,
            value: validJwt,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.write(
            key: SecureStorageKeys.refreshToken,
            value: testRefreshToken,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.write(
            key: SecureStorageKeys.customUserId,
            value: 'user_abc123',
          ),
        ).thenThrow(writeError);
        when(
          () => mockStorage.delete(key: SecureStorageKeys.accessToken),
        ).thenThrow(Exception('rollback delete failed'));
        when(
          () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
        ).thenAnswer((_) async {});
        final storage = container.read(tokenStorageProvider);

        await check(
          storage.saveTokens(
            accessToken: validJwt,
            refreshToken: testRefreshToken,
          ),
        ).throws<Exception>((it) => it.equals(writeError));

        verify(
          () => mockStorage.delete(key: SecureStorageKeys.accessToken),
        ).called(1);
        verify(
          () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
        ).called(1);
        verifyNever(
          () => mockStorage.delete(key: SecureStorageKeys.customUserId),
        );
      },
    );

    test('saveTokens: sub無しトークン保存時に古い customUserId の削除に失敗した場合は '
        '既書込の accessToken / refreshToken を削除して再スローすること', () async {
      final deleteError = Exception('delete customUserId failed');
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: testAccessToken,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: testRefreshToken,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: SecureStorageKeys.customUserId),
      ).thenThrow(deleteError);
      when(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      ).thenAnswer((_) async {});
      final storage = container.read(tokenStorageProvider);

      await check(
        storage.saveTokens(
          accessToken: testAccessToken,
          refreshToken: testRefreshToken,
        ),
      ).throws<Exception>((it) => it.equals(deleteError));

      verify(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).called(1);
      verify(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      ).called(1);
    });

    test('saveTokens(preserveExistingOnFailure: true): 書込失敗時に書込前の既存値を復元して保持し、 '
        '書込前が null だったキーのみ削除すること', () async {
      const oldAccess = 'old_access_token';
      const oldRefresh = 'old_refresh_token';
      const newJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJ1c2VyX2FiYzEyMyJ9.'
          'dummy_signature';
      final writeError = Exception('customUserId write failed');

      when(
        () => mockStorage.read(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async => oldAccess);
      when(
        () => mockStorage.read(key: SecureStorageKeys.refreshToken),
      ).thenAnswer((_) async => oldRefresh);
      when(
        () => mockStorage.read(key: SecureStorageKeys.customUserId),
      ).thenAnswer((_) async => null);

      when(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: newJwt,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: oldRefresh,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.customUserId,
          value: 'user_abc123',
        ),
      ).thenThrow(writeError);
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: oldAccess,
        ),
      ).thenAnswer((_) async {});
      final storage = container.read(tokenStorageProvider);

      await check(
        storage.saveTokens(
          accessToken: newJwt,
          refreshToken: oldRefresh,
          preserveExistingOnFailure: true,
        ),
      ).throws<Exception>((it) => it.equals(writeError));

      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: oldAccess,
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: oldRefresh,
        ),
      ).called(2);
      verifyNever(() => mockStorage.delete(key: SecureStorageKeys.accessToken));
      verifyNever(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      );

      // 書込前の accessToken が null・refreshToken のみ存在していた場合は
      // accessToken のみ削除し、元例外を再スローすること
      const jwtNoSub = 'new_access_without_sub';
      final refreshError = Exception('refresh write failed');
      when(
        () => mockStorage.read(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.accessToken,
          value: jwtNoSub,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.write(
          key: SecureStorageKeys.refreshToken,
          value: oldRefresh,
        ),
      ).thenThrow(refreshError);
      when(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async {});

      await check(
        storage.saveTokens(
          accessToken: jwtNoSub,
          refreshToken: oldRefresh,
          preserveExistingOnFailure: true,
        ),
      ).throws<Exception>((it) => it.equals(refreshError));

      verify(
        () => mockStorage.delete(key: SecureStorageKeys.accessToken),
      ).called(1);
      verifyNever(
        () => mockStorage.delete(key: SecureStorageKeys.refreshToken),
      );
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
