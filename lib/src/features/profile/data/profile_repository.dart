import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
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
  const ProfileRepository({
    required this.api,
    required this.talker,
  });

  /// APIクライアント
  final ApiClient api;

  /// ロガー
  final Talker talker;

  /// プロフィール情報を取得する (GET /users/me)
  Future<UserProfile> fetchProfile() async {
    talker.debug('Fetching profile from API...');
    final response = await api.get<Map<String, dynamic>>('/users/me');

    if (response.data case final Map<String, dynamic> data) {
      talker.debug('Successfully fetched profile from API.');
      return UserProfile.fromJson(data);
    }

    talker.error('Failed to parse profile data: Response data is invalid.');
    throw const AppException.dataParse(message: 'Failed to parse profile data');
  }

  /// プロフィール情報を更新する (PUT /users/me)
  Future<UserProfile> updateProfile(UserProfile profile) async {
    talker.debug('Updating profile via API...');
    final response = await api.put<Map<String, dynamic>>(
      '/users/me',
      data: profile.toJson(),
    );

    if (response.data case final Map<String, dynamic> data) {
      talker.debug('Successfully updated profile via API.');
      return UserProfile.fromJson(data);
    }

    talker.error(
      'Failed to parse updated profile data: Response data is invalid.',
    );
    throw const AppException.dataParse(
      message: 'Failed to parse updated profile data',
    );
  }
}
