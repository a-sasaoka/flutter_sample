// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Authenticationを使用した認証リポジトリ

@ProviderFor(FirebaseAuthRepository)
const firebaseAuthRepositoryProvider = FirebaseAuthRepositoryProvider._();

/// Firebase Authenticationを使用した認証リポジトリ
final class FirebaseAuthRepositoryProvider
    extends $NotifierProvider<FirebaseAuthRepository, User?> {
  /// Firebase Authenticationを使用した認証リポジトリ
  const FirebaseAuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthRepositoryHash();

  @$internal
  @override
  FirebaseAuthRepository create() => FirebaseAuthRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$firebaseAuthRepositoryHash() =>
    r'f9db8f9239f5f0c5158ca3b8b242f9afc851d94b';

/// Firebase Authenticationを使用した認証リポジトリ

abstract class _$FirebaseAuthRepository extends $Notifier<User?> {
  User? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<User?, User?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<User?, User?>,
              User?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
