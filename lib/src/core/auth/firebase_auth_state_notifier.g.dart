// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_auth_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Authenticationの認証状態を管理するStateNotifier

@ProviderFor(FirebaseAuthStateNotifier)
const firebaseAuthStateProvider = FirebaseAuthStateNotifierProvider._();

/// Firebase Authenticationの認証状態を管理するStateNotifier
final class FirebaseAuthStateNotifierProvider
    extends $NotifierProvider<FirebaseAuthStateNotifier, User?> {
  /// Firebase Authenticationの認証状態を管理するStateNotifier
  const FirebaseAuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthStateNotifierHash();

  @$internal
  @override
  FirebaseAuthStateNotifier create() => FirebaseAuthStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$firebaseAuthStateNotifierHash() =>
    r'ca5a5b8593483c219f77538e6db37b03ef17e180';

/// Firebase Authenticationの認証状態を管理するStateNotifier

abstract class _$FirebaseAuthStateNotifier extends $Notifier<User?> {
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
