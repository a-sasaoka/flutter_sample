import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_auth_state_notifier.g.dart';

/// Firebase Authenticationの認証状態を管理するStateNotifier
@Riverpod(keepAlive: true)
class FirebaseAuthStateNotifier extends _$FirebaseAuthStateNotifier {
  @override
  AsyncValue<User?> build() {
    // 認証状態の監視ストリームをそのまま状態として管理する
    return ref.watch(authStateChangesProvider);
  }
}
