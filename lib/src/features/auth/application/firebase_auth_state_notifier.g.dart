// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_auth_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Authenticationの認証状態を管理するStateNotifier

@ProviderFor(FirebaseAuthStateNotifier)
final firebaseAuthStateProvider = FirebaseAuthStateNotifierProvider._();

/// Firebase Authenticationの認証状態を管理するStateNotifier
final class FirebaseAuthStateNotifierProvider
    extends $NotifierProvider<FirebaseAuthStateNotifier, AsyncValue<User?>> {
  /// Firebase Authenticationの認証状態を管理するStateNotifier
  FirebaseAuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthStateNotifierHash();

  @$internal
  @override
  FirebaseAuthStateNotifier create() => FirebaseAuthStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<User?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<User?>>(value),
    );
  }
}

String _$firebaseAuthStateNotifierHash() =>
    r'ce7898dbee8ee494000ad238268cb078816d89fd';

/// Firebase Authenticationの認証状態を管理するStateNotifier

abstract class _$FirebaseAuthStateNotifier
    extends $Notifier<AsyncValue<User?>> {
  AsyncValue<User?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<User?>, AsyncValue<User?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<User?>, AsyncValue<User?>>,
              AsyncValue<User?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
