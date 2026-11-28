import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// トークンストレージプロバイダー
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return TokenStorage(secureStorage: secureStorage);
}

/// トークンストレージクラス
class TokenStorage {
  /// コンストラクタ
  const TokenStorage({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  /// トークンおよび識別情報を保存する
  ///
  /// 途中で書き込みに失敗した場合は例外を再スローします。
  /// [preserveExistingOnFailure] が `false` の場合（ログイン経路）は、この呼び出しで
  /// 書き込んだキーを削除して中途半端な資格情報が残らないようにします。
  /// `true` の場合（トークンリフレッシュ経路）は、書き込み前に保持していた
  /// 有効な資格情報を復元して保持します。
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? email,
    bool preserveExistingOnFailure = false,
  }) async {
    final previousValues = preserveExistingOnFailure
        ? <String, String?>{
            SecureStorageKeys.accessToken: await _secureStorage.read(
              key: SecureStorageKeys.accessToken,
            ),
            SecureStorageKeys.refreshToken: await _secureStorage.read(
              key: SecureStorageKeys.refreshToken,
            ),
            SecureStorageKeys.customUserId: await _secureStorage.read(
              key: SecureStorageKeys.customUserId,
            ),
            SecureStorageKeys.customUserEmail: await _secureStorage.read(
              key: SecureStorageKeys.customUserEmail,
            ),
          }
        : null;
    final modifiedKeys = <String>[];
    try {
      await _secureStorage.write(
        key: SecureStorageKeys.accessToken,
        value: accessToken,
      );
      modifiedKeys.add(SecureStorageKeys.accessToken);

      await _secureStorage.write(
        key: SecureStorageKeys.refreshToken,
        value: refreshToken,
      );
      modifiedKeys.add(SecureStorageKeys.refreshToken);

      // ユーザーID（sub 優先、次点で指定値）を暗号化保存（未確定時は古い ID の残留を防ぐため削除）
      final resolvedUserId =
          _normalizeIdentity(JwtUtils.getUserId(accessToken)) ??
          _normalizeIdentity(userId);
      await _persistOptionalKey(
        SecureStorageKeys.customUserId,
        value: resolvedUserId,
        previousValues: previousValues,
        modifiedKeys: modifiedKeys,
      );

      // メールアドレス（email クレーム優先、次点で入力メール等）を暗号化保存（未確定時は古いメールを削除）
      final resolvedEmail =
          _normalizeIdentity(JwtUtils.getEmail(accessToken)) ??
          _normalizeIdentity(email);
      await _persistOptionalKey(
        SecureStorageKeys.customUserEmail,
        value: resolvedEmail,
        previousValues: previousValues,
        modifiedKeys: modifiedKeys,
      );
    } on Object {
      for (final key in modifiedKeys) {
        try {
          await _rollbackKey(key, previousValue: previousValues?[key]);
        } on Object catch (_) {
          // 元の書き込み例外を優先して伝播させるため、ロールバック時の復元/削除失敗は無視する
        }
      }
      rethrow;
    }
  }

  Future<void> _persistOptionalKey(
    String key, {
    required String? value,
    required Map<String, String?>? previousValues,
    required List<String> modifiedKeys,
  }) async {
    if (value != null) {
      await _secureStorage.write(key: key, value: value);
      modifiedKeys.add(key);
    } else {
      await _secureStorage.delete(key: key);
      if (previousValues?[key] != null) {
        modifiedKeys.add(key);
      }
    }
  }

  Future<void> _rollbackKey(
    String key, {
    required String? previousValue,
  }) async {
    if (previousValue != null) {
      await _secureStorage.write(key: key, value: previousValue);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: SecureStorageKeys.accessToken);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: SecureStorageKeys.refreshToken);
  }

  /// ログイン中ユーザーIDを取得する（未保存時はアクセストークンからの復元も試行）
  Future<String?> getUserId() async {
    return await _getOrRecoverIdentity(
      key: SecureStorageKeys.customUserId,
      extractFromToken: JwtUtils.getUserId,
    );
  }

  /// ログイン中メールアドレスを取得する（未保存時はアクセストークンからの復元も試行）
  Future<String?> getUserEmail() async {
    return await _getOrRecoverIdentity(
      key: SecureStorageKeys.customUserEmail,
      extractFromToken: JwtUtils.getEmail,
    );
  }

  Future<String?> _getOrRecoverIdentity({
    required String key,
    required String? Function(String token) extractFromToken,
  }) async {
    final storedValue = _normalizeIdentity(await _secureStorage.read(key: key));
    if (storedValue != null) {
      return storedValue;
    }

    // 後方互換性：トークンから復元して保存
    final token = await getAccessToken();
    if (token != null) {
      final recovered = _normalizeIdentity(extractFromToken(token));
      if (recovered != null) {
        await _secureStorage.write(key: key, value: recovered);
        return recovered;
      }
    }
    return null;
  }

  static String? _normalizeIdentity(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// トークンおよびユーザー識別情報を削除する
  ///
  /// 4件のうち途中で失敗しても残りのキーの削除を最後まで試行し、
  /// 一部トークンの残留を防いだ上で最初に発生したエラーを再スローします。
  Future<void> clear() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    const keys = [
      SecureStorageKeys.accessToken,
      SecureStorageKeys.refreshToken,
      SecureStorageKeys.customUserId,
      SecureStorageKeys.customUserEmail,
    ];

    for (final key in keys) {
      try {
        await _secureStorage.delete(key: key);
      } on Object catch (e, st) {
        // 途中で失敗しても残りのキーをすべて削除試行するため、最初のエラーだけ控える
        firstError ??= e;
        firstStackTrace ??= st;
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }
}
