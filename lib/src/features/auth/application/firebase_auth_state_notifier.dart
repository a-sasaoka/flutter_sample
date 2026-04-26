import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_auth_state_notifier.g.dart';

/// Firebase Authenticationの認証状態を管理するStateNotifier
@riverpod
class FirebaseAuthStateNotifier extends _$FirebaseAuthStateNotifier {
  @override
  User? build() {
    // 新しく作成した StreamProvider を監視し、
    // 最新の非同期データ（User?）を同期的に返すようにする
    final asyncUser = ref.watch(authStateChangesProvider);
    return asyncUser.value;
  }
}
