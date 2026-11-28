import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/firebase_auth_error_codes.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'profile_repository.g.dart';

/// ProfileRepositoryを提供するプロバイダ
@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(
    api: ref.watch(apiClientProvider),
    talker: ref.watch(loggerProvider),
  );
}

/// プロフィールに関する通信を管理するリポジトリ
class ProfileRepository {
  /// コンストラクタ
  const ProfileRepository({required this.api, required this.talker});

  /// APIクライアント
  final ApiClient api;

  /// ロガー
  final Talker talker;

  /// プロフィール情報を取得する (GET /users/me)
  Future<UserProfile> fetchProfile() async {
    talker.debug('Fetching profile from API...');
    final response = await api.get<Map<String, dynamic>>('/users/me');
    final profile = _parseProfile(
      response.data,
      'Failed to parse profile data',
    );
    talker.debug('Successfully fetched profile from API.');
    return profile;
  }

  /// プロフィール情報を更新する (PUT /users/me)
  Future<UserProfile> updateProfile(UserProfile profile) async {
    talker.debug('Updating profile via API...');
    final response = await api.put<Map<String, dynamic>>(
      '/users/me',
      data: profile.toJson(),
    );
    final updated = _parseProfile(
      response.data,
      'Failed to parse updated profile data',
    );
    talker.debug('Successfully updated profile via API.');
    return updated;
  }

  /// ログイン中ユーザーのアカウントデータ（プロフィール・メモ等）をサーバーから削除する (DELETE /users/me)
  ///
  /// サーバーから `403`（`code: requires-recent-login`）が返された場合は、
  /// 再認証・再試行フローへ繋ぐため [ReauthRequiresRecentLoginException] をスローします。
  Future<void> deleteMyAccountData() async {
    talker.debug('Deleting account data via API...');
    try {
      await api.delete<void>('/users/me');
    } on DioException catch (e) {
      final response = e.response;
      final data = response?.data;
      if (response?.statusCode == 403 &&
          data is Map &&
          data['code'] == FirebaseAuthErrorCodes.requiresRecentLogin) {
        talker.warning('Server account data deletion requires recent login.');
        throw const ReauthRequiresRecentLoginException();
      }
      rethrow;
    }
    talker.debug('Successfully deleted account data via API.');
  }

  UserProfile _parseProfile(Object? responseData, String errorMessage) {
    if (responseData case final Map<String, dynamic> data) {
      try {
        return UserProfile.fromJson(data);
      } on Object catch (e, st) {
        talker.handle(e, st, '$errorMessage: Failed to parse UserProfile');
        throw const AppException.dataParse();
      }
    }
    talker.handle(
      const AppException.dataParse(),
      StackTrace.current,
      '$errorMessage: Response data is invalid.',
    );
    throw const AppException.dataParse();
  }
}
