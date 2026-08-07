import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sample/main.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/app_lock/data/local_authentication_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// E2Eテスト用に一時ファイル上で安全に Key-Value を保存・復元する SecureStorage フェイク
class FakeSecureStorage extends FlutterSecureStorage {
  static final File _file = File(
    '${Directory.systemTemp.path}/e2e_secure_storage.json',
  );

  Map<String, String> _readStorage() {
    if (!_file.existsSync()) {
      return {};
    }
    final content = _file.readAsStringSync();
    final decoded = jsonDecode(content);
    if (decoded is Map) {
      return Map<String, String>.from(decoded);
    }
    return {};
  }

  void _writeStorage(Map<String, String> data) {
    _file.writeAsStringSync(jsonEncode(data));
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final storage = _readStorage();
    if (value == null) {
      storage.remove(key);
    } else {
      storage[key] = value;
    }
    _writeStorage(storage);
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final storage = _readStorage();
    return storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final storage = _readStorage()..remove(key);
    _writeStorage(storage);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _writeStorage({});
  }
}

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

/// E2Eテスト用に常に生体認証非対応（canCheckBiometrics = false）として振る舞うフェイククラス
class FakeLocalAuthentication extends LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => false;

  @override
  Future<bool> isDeviceSupported() async => false;
}

Future<void> main() async {
  // Flutterのシステム初期化
  WidgetsFlutterBinding.ensureInitialized();

  final fakeStorage = FakeSecureStorage();

  await mainCommon(
    Flavor.local,
    additionalOverrides: [
      // 0. セキュアストレージをファイルベースのフェイクに置き換え (プロセス再起動後も状態維持)
      secureStorageProvider.overrideWithValue(fakeStorage),
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
      // 5. 生体認証を「利用不可」に固定してテストを安定化
      localAuthenticationProvider.overrideWithValue(
        FakeLocalAuthentication(),
      ),
    ],
  );
}
