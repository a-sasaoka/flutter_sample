import 'package:flutter/material.dart';
import 'package:flutter_sample/main.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// E2Eテスト用にモック化した認証リポジトリ
class MockAuthRepository implements AuthRepository {
  /// コンストラクタ
  MockAuthRepository({required this.tokenStorage});

  @override
  ApiClient get api =>
      throw UnimplementedError('E2E mock auth has no API client');

  @override
  final TokenStorage tokenStorage;

  @override
  Future<void> login(String email, String password) async {
    // どんなIDとパスワードでも、常にダミートークンを保存してログイン成功とする
    await tokenStorage.saveTokens(
      accessToken: 'dummy_access_token',
      refreshToken: 'dummy_refresh_token',
    );
  }

  @override
  Future<bool> refreshToken() async {
    return true;
  }
}

/// E2Eテスト用に常に「アップデートなし」を返すモックコントローラ
class FakeUpdateRequestController extends UpdateRequestController {
  @override
  Future<UpdateRequestType> build() async {
    return UpdateRequestType.not; // 常にアップデートなし
  }
}

Future<void> main() async {
  // Flutterのシステム初期化
  WidgetsFlutterBinding.ensureInitialized();

  // E2Eテスト開始前に古いキーチェーン（SecureStorage）のトークンを強制消去する
  final container = ProviderContainer();
  final tokenStorage = container.read(tokenStorageProvider);
  await tokenStorage.clear();
  container.dispose();

  await mainCommon(
    Flavor.local,
    additionalOverrides: [
      // 1. Firebase Auth を無効化し、通常のログインフロー（API通信）として動作させる設定
      envConfigProvider.overrideWith((ref) {
        return const EnvConfigState(
          baseUrl: 'http://localhost:3000',
          aiModel: 'gemini-2.5-flash',
          connectTimeout: 10,
          receiveTimeout: 15,
          sendTimeout: 10,
          useFirebaseAuth: false, // Firebase Authを無効化
        );
      }),
      // 2. ネットワーク状態を「オフライン」として固定（これでサーバーとの不要なAPI通信を防ぎます）
      isOnlineProvider.overrideWithValue(false),
      // 3. ログイン処理をダミー（モック）に差し替え
      authRepositoryProvider.overrideWith((ref) {
        return MockAuthRepository(
          tokenStorage: ref.watch(tokenStorageProvider),
        );
      }),
      // 4. アップデート要求を「なし」に固定
      updateRequestControllerProvider.overrideWith(
        FakeUpdateRequestController.new,
      ),
    ],
  );
}
