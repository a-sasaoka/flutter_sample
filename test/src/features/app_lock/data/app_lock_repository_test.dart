import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/features/app_lock/data/app_lock_repository.dart';
import 'package:flutter_sample/src/features/app_lock/data/local_authentication_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;
  late AppLockRepository repository;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    repository = AppLockRepository(
      secureStorage: mockSecureStorage,
      localAuth: mockLocalAuth,
    );
  });

  group('AppLockRepository Tests', () {
    test('hasPasscode: パスコードが保存されている場合は true を返す', () async {
      when(
        () => mockSecureStorage.read(key: 'app_lock_passcode'),
      ).thenAnswer((_) async => '1234');

      final result = await repository.hasPasscode();

      check(result).isTrue();
      verify(() => mockSecureStorage.read(key: 'app_lock_passcode')).called(1);
    });

    test('hasPasscode: パスコードが保存されていない場合は false を返す', () async {
      when(
        () => mockSecureStorage.read(key: 'app_lock_passcode'),
      ).thenAnswer((_) async => null);

      final result = await repository.hasPasscode();

      check(result).isFalse();
    });

    test('savePasscode: パスコードを安全に保存する', () async {
      when(
        () => mockSecureStorage.write(
          key: 'app_lock_passcode',
          value: '5678',
        ),
      ).thenAnswer((_) async {});

      await repository.savePasscode('5678');

      verify(
        () => mockSecureStorage.write(
          key: 'app_lock_passcode',
          value: '5678',
        ),
      ).called(1);
    });

    test('verifyPasscode: 正しいパスコードの照合に成功する', () async {
      when(
        () => mockSecureStorage.read(key: 'app_lock_passcode'),
      ).thenAnswer((_) async => '1234');

      final isValid = await repository.verifyPasscode('1234');

      check(isValid).isTrue();
    });

    test('verifyPasscode: 誤ったパスコードの場合は false を返す', () async {
      when(
        () => mockSecureStorage.read(key: 'app_lock_passcode'),
      ).thenAnswer((_) async => '1234');

      final isValid = await repository.verifyPasscode('9999');

      check(isValid).isFalse();
    });

    test('isBiometricEnabled: 生体認証が有効な場合は true を返す', () async {
      when(
        () => mockSecureStorage.read(key: 'app_lock_biometric_enabled'),
      ).thenAnswer((_) async => 'true');

      final result = await repository.isBiometricEnabled();

      check(result).isTrue();
    });

    test('isBiometricEnabled: 生体認証が無効な場合は false を返す', () async {
      when(
        () => mockSecureStorage.read(key: 'app_lock_biometric_enabled'),
      ).thenAnswer((_) async => 'false');

      final result = await repository.isBiometricEnabled();

      check(result).isFalse();
    });

    test('setBiometricEnabled: 生体認証設定を保存する', () async {
      when(
        () => mockSecureStorage.write(
          key: 'app_lock_biometric_enabled',
          value: 'true',
        ),
      ).thenAnswer((_) async {});

      await repository.setBiometricEnabled(enabled: true);

      verify(
        () => mockSecureStorage.write(
          key: 'app_lock_biometric_enabled',
          value: 'true',
        ),
      ).called(1);
    });

    test('canCheckBiometrics: 端末が対応し、登録済み生体認証が存在する場合は true を返す', () async {
      when(
        () => mockLocalAuth.isDeviceSupported(),
      ).thenAnswer((_) async => true);
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.face]);

      final result = await repository.canCheckBiometrics();

      check(result).isTrue();
    });

    test('canCheckBiometrics: 生体認証が未登録の場合は false を返す', () async {
      when(
        () => mockLocalAuth.isDeviceSupported(),
      ).thenAnswer((_) async => true);
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => []);

      final result = await repository.canCheckBiometrics();

      check(result).isFalse();
    });

    test('canCheckBiometrics: 例外発生時は false を返す', () async {
      when(
        () => mockLocalAuth.isDeviceSupported(),
      ).thenThrow(Exception('Native error'));

      final result = await repository.canCheckBiometrics();

      check(result).isFalse();
    });

    test('authenticateWithBiometrics: 生体認証成功時は true を返す', () async {
      when(
        () => mockLocalAuth.authenticate(
          localizedReason: 'Reason',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.authenticateWithBiometrics(
        localizedReason: 'Reason',
      );

      check(result).isTrue();
    });

    test('authenticateWithBiometrics: 例外発生時は false を返す', () async {
      when(
        () => mockLocalAuth.authenticate(
          localizedReason: 'Reason',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        ),
      ).thenThrow(Exception('Auth canceled'));

      final result = await repository.authenticateWithBiometrics(
        localizedReason: 'Reason',
      );

      check(result).isFalse();
    });

    test('clearAll: ロック設定をすべて削除する', () async {
      when(
        () => mockSecureStorage.delete(key: 'app_lock_passcode'),
      ).thenAnswer((_) async {});
      when(
        () => mockSecureStorage.delete(key: 'app_lock_biometric_enabled'),
      ).thenAnswer((_) async {});

      await repository.clearAll();

      verify(
        () => mockSecureStorage.delete(key: 'app_lock_passcode'),
      ).called(1);
      verify(
        () => mockSecureStorage.delete(key: 'app_lock_biometric_enabled'),
      ).called(1);
    });

    test('appLockRepositoryProvider: 正常に AppLockRepository インスタンスを生成する', () {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          localAuthenticationProvider.overrideWithValue(mockLocalAuth),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(appLockRepositoryProvider);
      check(repo).isA<AppLockRepository>();
    });
  });
}
