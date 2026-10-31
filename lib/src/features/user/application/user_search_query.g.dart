// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_search_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ユーザー検索クエリ（キーワード）を管理するプロバイダー

@ProviderFor(UserSearchQuery)
final userSearchQueryProvider = UserSearchQueryProvider._();

/// ユーザー検索クエリ（キーワード）を管理するプロバイダー
final class UserSearchQueryProvider
    extends $NotifierProvider<UserSearchQuery, String> {
  /// ユーザー検索クエリ（キーワード）を管理するプロバイダー
  UserSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSearchQueryHash();

  @$internal
  @override
  UserSearchQuery create() => UserSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$userSearchQueryHash() => r'cf2c324fa4f99b5506092fc42decff6599e98c1f';

/// ユーザー検索クエリ（キーワード）を管理するプロバイダー

abstract class _$UserSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 検索クエリによって絞り込まれたユーザー一覧を提供するプロバイダー

@ProviderFor(filteredUsers)
final filteredUsersProvider = FilteredUsersProvider._();

/// 検索クエリによって絞り込まれたユーザー一覧を提供するプロバイダー

final class FilteredUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<(List<UserModel>, DateTime?)>,
          AsyncValue<(List<UserModel>, DateTime?)>,
          AsyncValue<(List<UserModel>, DateTime?)>
        >
    with $Provider<AsyncValue<(List<UserModel>, DateTime?)>> {
  /// 検索クエリによって絞り込まれたユーザー一覧を提供するプロバイダー
  FilteredUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredUsersHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<(List<UserModel>, DateTime?)>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<(List<UserModel>, DateTime?)> create(Ref ref) {
    return filteredUsers(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<(List<UserModel>, DateTime?)> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<(List<UserModel>, DateTime?)>>(value),
    );
  }
}

String _$filteredUsersHash() => r'd820318a8e6baa2106a96f5d590f698ecf04049f';
