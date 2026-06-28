import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_token_storage.dart';

/// 認証関連のプロバイダーの動的切り替えオーバーライド一覧を取得します。
List<dynamic> getAuthOverrides() {
  return [
    tokenStorageProvider.overrideWith((ref) {
      final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;
      if (useFirebase) {
        return FirebaseAuthTokenStorage(ref.watch(firebaseAuthProvider));
      }
      return TokenStorage(secureStorage: ref.watch(secureStorageProvider));
    }),
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
  ];
}
