// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Authenticationのインスタンスを返す

@ProviderFor(firebaseAuth)
const firebaseAuthProvider = FirebaseAuthProvider._();

/// Firebase Authenticationのインスタンスを返す

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  /// Firebase Authenticationのインスタンスを返す
  const FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'8f84097cccd00af817397c1715c5f537399ba780';

/// Google Sign Inのインスタンスを返す

@ProviderFor(googleSignIn)
const googleSignInProvider = GoogleSignInProvider._();

/// Google Sign Inのインスタンスを返す

final class GoogleSignInProvider
    extends $FunctionalProvider<GoogleSignIn, GoogleSignIn, GoogleSignIn>
    with $Provider<GoogleSignIn> {
  /// Google Sign Inのインスタンスを返す
  const GoogleSignInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleSignInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleSignInHash();

  @$internal
  @override
  $ProviderElement<GoogleSignIn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoogleSignIn create(Ref ref) {
    return googleSignIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleSignIn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleSignIn>(value),
    );
  }
}

String _$googleSignInHash() => r'16cf38da6ba66b02462d5ad518f809a45382089f';

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
    r'3b6a6213867c92491e2215d3d556f4b3aaa40a1d';

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
