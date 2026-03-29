import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_auth_state_notifier.g.dart';

/// Firebase Authenticationの認証状態を管理するStateNotifier
@riverpod
class FirebaseAuthStateNotifier extends _$FirebaseAuthStateNotifier {
  @override
  User? build() {
    // ref.watch を使うことで、firebaseAuthRepositoryProvider の
    // 状態が更新された際に自動的に検知して再構築してくれます。
    return ref.watch(firebaseAuthRepositoryProvider);
  }
}
