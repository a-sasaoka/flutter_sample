import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/auth/firebase_auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_auth_state_notifier.g.dart';

/// Firebase Authenticationの認証状態を管理するStateNotifier
@riverpod
class FirebaseAuthStateNotifier extends _$FirebaseAuthStateNotifier {
  @override
  User? build() {
    // 初期状態は repository の現在ログインユーザーで決定
    final user = ref.read(firebaseAuthRepositoryProvider);

    // FirebaseAuth の状態変化監視
    ref.listen<User?>(
      firebaseAuthRepositoryProvider.select((repo) => repo),
      (_, _) => state = ref.read(firebaseAuthRepositoryProvider),
    );

    return user;
  }
}
