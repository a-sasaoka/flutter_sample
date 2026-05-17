// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// UserNotifier

@ProviderFor(UserNotifier)
final userProvider = UserNotifierProvider._();

/// UserNotifier
final class UserNotifierProvider
    extends $AsyncNotifierProvider<UserNotifier, (List<UserModel>, DateTime?)> {
  /// UserNotifier
  UserNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userNotifierHash();

  @$internal
  @override
  UserNotifier create() => UserNotifier();
}

String _$userNotifierHash() => r'dd5aa3c8c2f1267a1cfe03bc304e847cae8dd2a0';

/// UserNotifier

abstract class _$UserNotifier
    extends $AsyncNotifier<(List<UserModel>, DateTime?)> {
  FutureOr<(List<UserModel>, DateTime?)> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<(List<UserModel>, DateTime?)>,
              (List<UserModel>, DateTime?)
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<(List<UserModel>, DateTime?)>,
                (List<UserModel>, DateTime?)
              >,
              AsyncValue<(List<UserModel>, DateTime?)>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
