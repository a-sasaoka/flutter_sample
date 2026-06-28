import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モッククラスの定義 ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Talker talker;

  setUp(() {
    talker = Talker(
      settings: TalkerSettings(useConsoleLogs: false, useHistory: false),
    );
  });

  group('Auth Integration Tests (main.dart 相当のオーバーライド)', () {
    test(
      '【useFirebaseAuth: true】 の際、IDトークンが正しくヘッダーにセットされ、'
      ' リフレッシュ時にIDトークンが強制更新されること',
      () async {
        final mockFirebaseAuth = MockFirebaseAuth();
        final mockUser = MockUser();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.getIdToken).thenAnswer((_) async => 'mock_id_token');
        when(
          () => mockUser.getIdToken(true),
        ).thenAnswer((_) async => 'new_mock_id_token');

        // main.dart 相当の上書き設定を持ったコンテナを作成
        final container = ProviderContainer(
          overrides: [
            // 1. 環境フラグを true に設定
            envConfigProvider.overrideWithValue(
              const EnvConfigState(
                baseUrl: 'https://example.com',
                aiModel: 'gemini-2.5-flash',
                connectTimeout: 10,
                receiveTimeout: 15,
                sendTimeout: 10,
                useFirebaseAuth: true,
              ),
            ),
            // 2. TokenStorageを Firebase 用に上書き
            tokenStorageProvider.overrideWith((ref) {
              return FirebaseAuthTokenStorage(ref.watch(firebaseAuthProvider));
            }),
            // 3. リフレッシュコールバックを Firebase 用に上書き
            tokenRefreshCallbackProvider.overrideWith((ref) {
              final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;
              if (useFirebase) {
                return () async {
                  try {
                    final user = ref.read(firebaseAuthProvider).currentUser;
                    if (user != null) {
                      final token = await user.getIdToken(true);
                      return token != null;
                    }
                    return false;
                  } on Exception catch (_) {
                    return false;
                  }
                };
              }
              return ref.read(authRepositoryProvider).refreshToken;
            }),
            firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
            loggerProvider.overrideWithValue(talker),
          ],
        );

        // --- 認証ヘッダー付与の検証 ---
        final interceptor = container.read(tokenInterceptorProvider);
        final options = RequestOptions(path: '/test');
        final handler = RequestInterceptorHandler();

        await (interceptor as dynamic).onRequest(options, handler);

        // トークンが正しくセットされていること
        check(options.headers['Authorization']).equals('Bearer mock_id_token');

        // --- リフレッシュ処理の検証 ---
        final refreshCallback = container.read(tokenRefreshCallbackProvider);
        final refreshResult = await refreshCallback();

        // 強制更新が成功し、FirebaseのAPIが正しく叩かれていること
        check(refreshResult).isTrue();
        verify(() => mockUser.getIdToken(true)).called(1);
      },
    );

    test(
      '【useFirebaseAuth: false】 の際、SecureStorageからアクセストークンが取得され、'
      ' リフレッシュ時に自前サーバーAPIが呼ばれること',
      () async {
        final mockSecureStorage = MockFlutterSecureStorage();
        final mockAuthRepository = MockAuthRepository();

        when(
          () => mockSecureStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => 'mock_access_token');
        when(mockAuthRepository.refreshToken).thenAnswer((_) async => true);

        // main.dart 相当の上書き設定を持ったコンテナを作成
        final container = ProviderContainer(
          overrides: [
            // 1. 環境フラグを false に設定
            envConfigProvider.overrideWithValue(
              const EnvConfigState(
                baseUrl: 'https://example.com',
                aiModel: 'gemini-2.5-flash',
                connectTimeout: 10,
                receiveTimeout: 15,
                sendTimeout: 10,
                useFirebaseAuth: false,
              ),
            ),
            // 2. TokenStorage は上書きせずデフォルトのまま（SecureStorageを使用）
            secureStorageProvider.overrideWithValue(mockSecureStorage),
            // 3. リフレッシュコールバックを 自前サーバーAPI に上書き
            tokenRefreshCallbackProvider.overrideWith((ref) {
              final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;
              if (useFirebase) {
                return () async {
                  try {
                    final user = ref.read(firebaseAuthProvider).currentUser;
                    if (user != null) {
                      final token = await user.getIdToken(true);
                      return token != null;
                    }
                    return false;
                  } on Exception catch (_) {
                    return false;
                  }
                };
              }
              return ref.read(authRepositoryProvider).refreshToken;
            }),
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            loggerProvider.overrideWithValue(talker),
          ],
        );

        // --- 認証ヘッダー付与の検証 ---
        final interceptor = container.read(tokenInterceptorProvider);
        final options = RequestOptions(path: '/test');
        final handler = RequestInterceptorHandler();

        await (interceptor as dynamic).onRequest(options, handler);

        // SecureStorageから取得したアクセストークンがセットされていること
        check(
          options.headers['Authorization'],
        ).equals('Bearer mock_access_token');

        // --- リフレッシュ処理の検証 ---
        final refreshCallback = container.read(tokenRefreshCallbackProvider);
        final refreshResult = await refreshCallback();

        // 自前のリフレッシュAPIが正しく叩かれていること
        check(refreshResult).isTrue();
        verify(mockAuthRepository.refreshToken).called(1);
      },
    );
  });
}
