import 'dart:async';
import 'dart:io';

import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/data/storage_service.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_notifier.g.dart';

/// ユーザープロフィール情報を管理するNotifier
@riverpod
class Profile extends _$Profile {
  @override
  FutureOr<UserProfile> build() async {
    final talker = ref.watch(loggerProvider)
      ..debug('Building ProfileNotifier...');
    final profile = await ref.watch(profileRepositoryProvider).fetchProfile();
    talker.debug('ProfileNotifier build completed.');
    return profile;
  }

  /// プロフィール情報を更新する
  Future<void> updateProfile(
    UserProfile updatedProfile, {
    File? avatarFile,
    bool deleteAvatar = false,
  }) async {
    final talker = ref.read(loggerProvider);
    final previousState = state;
    // ignore: invalid_use_of_internal_member, copyWithPrevious is internal but required to preserve state value during save loader.
    state = const AsyncLoading<UserProfile>().copyWithPrevious(previousState);

    state = await AsyncValue.guard(() async {
      talker.debug('Starting profile update process...');

      final oldProfile = previousState.value;
      final oldAvatarUrl = oldProfile?.avatarUrl;
      var targetProfile = updatedProfile;
      String? newlyUploadedAvatarUrl;

      final useFirebase = ref.read(envConfigProvider).useFirebaseAuth;

      // 1. アバター画像のアップロードまたは削除処理
      if (useFirebase) {
        final userId = ref.read(firebaseAuthRepositoryProvider).currentUserId;
        if (userId == null) {
          talker.warning(
            'Cannot update profile: No user is currently signed in.',
          );
          throw const AppException.unauthenticated();
        }
        final storageService = ref.read(storageServiceProvider);

        if (avatarFile != null) {
          talker.debug(
            'Uploading new avatar to Firebase Storage for: '
            '$userId...',
          );
          newlyUploadedAvatarUrl = await storageService.uploadAvatar(
            userId: userId,
            file: avatarFile,
          );
          targetProfile = targetProfile.copyWith(
            avatarUrl: newlyUploadedAvatarUrl,
          );
        } else if (deleteAvatar) {
          targetProfile = targetProfile.copyWith(avatarUrl: '');
        }
      } else {
        talker.debug(
          'useFirebaseAuth is false. Skipping Firebase Storage upload.',
        );
        if (avatarFile != null) {
          // ローカルモック環境等では端末内のローカルファイルパスをそのまま保持
          targetProfile = targetProfile.copyWith(avatarUrl: avatarFile.path);
        } else if (deleteAvatar) {
          targetProfile = targetProfile.copyWith(avatarUrl: '');
        }
      }

      // 2. 自前サーバーのプロフィール情報を更新
      late final UserProfile newProfile;
      try {
        newProfile = await ref
            .read(profileRepositoryProvider)
            .updateProfile(targetProfile);
        talker.debug('Successfully updated profile on server.');
      } on Object catch (serverError, serverSt) {
        if (useFirebase && newlyUploadedAvatarUrl != null) {
          try {
            await ref
                .read(storageServiceProvider)
                .deleteAvatarByUrl(avatarUrl: newlyUploadedAvatarUrl);
          } on Object catch (e, st) {
            talker.handle(e, st, 'Failed to rollback uploaded avatar');
          }
        }
        talker.handle(
          serverError,
          serverSt,
          'Failed to update profile on server',
        );
        rethrow;
      }

      // 3. Firebase Auth との同期判定
      if (useFirebase) {
        talker.debug('useFirebaseAuth is true. Syncing to Firebase Auth...');
        try {
          await ref
              .read(firebaseAuthRepositoryProvider)
              .updateAuthProfile(
                displayName: newProfile.displayName,
                email: newProfile.email,
                photoUrl: (avatarFile != null || deleteAvatar)
                    ? newProfile.avatarUrl
                    : null,
              );
          talker.debug('Successfully synced to Firebase Auth.');
        } on Object catch (_) {
          talker.error(
            'Failed to sync to Firebase Auth. Rolling back server update...',
          );
          var serverRollbackSucceeded = false;
          if (oldProfile != null) {
            try {
              await ref
                  .read(profileRepositoryProvider)
                  .updateProfile(oldProfile);
              serverRollbackSucceeded = true;
              talker.debug('Successfully rolled back server update.');
            } on Object catch (rollbackError, rollbackSt) {
              talker.handle(
                rollbackError,
                rollbackSt,
                'Failed to rollback server update',
              );
            }
          } else {
            serverRollbackSucceeded = true;
          }

          if (serverRollbackSucceeded && newlyUploadedAvatarUrl != null) {
            try {
              await ref
                  .read(storageServiceProvider)
                  .deleteAvatarByUrl(avatarUrl: newlyUploadedAvatarUrl);
            } on Object catch (e, st) {
              talker.handle(e, st, 'Failed to rollback uploaded avatar');
            }
          }
          rethrow;
        }

        // 4. 更新・同期完了後に旧アバター画像を削除
        final shouldDeleteOldAvatar =
            (newlyUploadedAvatarUrl != null || deleteAvatar) &&
            oldAvatarUrl != null &&
            oldAvatarUrl.isNotEmpty &&
            (oldAvatarUrl.startsWith('http://') ||
                oldAvatarUrl.startsWith('https://') ||
                oldAvatarUrl.startsWith('gs://'));
        if (shouldDeleteOldAvatar) {
          try {
            await ref
                .read(storageServiceProvider)
                .deleteAvatarByUrl(avatarUrl: oldAvatarUrl);
            talker.debug('Successfully deleted old avatar from Storage.');
          } on Object catch (e, st) {
            talker.handle(e, st, 'Failed to delete old avatar after update');
          }
        }
      } else {
        talker.debug('useFirebaseAuth is false. Skipping Firebase Auth sync.');
      }

      return newProfile;
    });
  }
}
