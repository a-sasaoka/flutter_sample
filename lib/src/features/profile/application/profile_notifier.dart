import 'dart:async';

import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
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
  Future<void> updateProfile(UserProfile updatedProfile) async {
    final talker = ref.read(loggerProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      talker.debug('Starting profile update process...');

      // 1. 自前サーバーのプロフィール情報を更新
      final newProfile = await ref
          .read(profileRepositoryProvider)
          .updateProfile(updatedProfile);
      talker.debug('Successfully updated profile on server.');

      // 2. Firebase Auth との同期判定
      final useFirebase = ref.read(envConfigProvider).useFirebaseAuth;
      if (useFirebase) {
        talker.debug('useFirebaseAuth is true. Syncing to Firebase Auth...');
        await ref
            .read(firebaseAuthRepositoryProvider)
            .updateAuthProfile(
              displayName: newProfile.displayName,
              email: newProfile.email,
            );
        talker.debug('Successfully synced to Firebase Auth.');
      } else {
        talker.debug('useFirebaseAuth is false. Skipping Firebase Auth sync.');
      }

      return newProfile;
    });
  }
}
