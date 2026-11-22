// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_auth_invalidation_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリケーションサポートディレクトリを取得する関数を提供するプロバイダ
///
/// テスト時は一時ディレクトリを返す関数で差し替えることで、実ファイルシステム上で
/// 永続化・復旧処理を検証できます。

@ProviderFor(appSupportDirectoryReader)
final appSupportDirectoryReaderProvider = AppSupportDirectoryReaderProvider._();

/// アプリケーションサポートディレクトリを取得する関数を提供するプロバイダ
///
/// テスト時は一時ディレクトリを返す関数で差し替えることで、実ファイルシステム上で
/// 永続化・復旧処理を検証できます。

final class AppSupportDirectoryReaderProvider
    extends
        $FunctionalProvider<
          Future<Directory> Function(),
          Future<Directory> Function(),
          Future<Directory> Function()
        >
    with $Provider<Future<Directory> Function()> {
  /// アプリケーションサポートディレクトリを取得する関数を提供するプロバイダ
  ///
  /// テスト時は一時ディレクトリを返す関数で差し替えることで、実ファイルシステム上で
  /// 永続化・復旧処理を検証できます。
  AppSupportDirectoryReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSupportDirectoryReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSupportDirectoryReaderHash();

  @$internal
  @override
  $ProviderElement<Future<Directory> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<Directory> Function() create(Ref ref) {
    return appSupportDirectoryReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<Directory> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<Directory> Function()>(value),
    );
  }
}

String _$appSupportDirectoryReaderHash() =>
    r'b84b87986607a62fcc8bb6aa785c7b519c6f058f';

/// 親ディレクトリをディスクへ同期する関数を提供するプロバイダ

@ProviderFor(directorySyncer)
final directorySyncerProvider = DirectorySyncerProvider._();

/// 親ディレクトリをディスクへ同期する関数を提供するプロバイダ

final class DirectorySyncerProvider
    extends
        $FunctionalProvider<DirectorySyncer, DirectorySyncer, DirectorySyncer>
    with $Provider<DirectorySyncer> {
  /// 親ディレクトリをディスクへ同期する関数を提供するプロバイダ
  DirectorySyncerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directorySyncerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directorySyncerHash();

  @$internal
  @override
  $ProviderElement<DirectorySyncer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DirectorySyncer create(Ref ref) {
    return directorySyncer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectorySyncer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectorySyncer>(value),
    );
  }
}

String _$directorySyncerHash() => r'f67e0ca43684cff43e1e73641ae876ba67bc0061';

/// [CustomAuthInvalidationStore] のプロバイダ

@ProviderFor(customAuthInvalidationStore)
final customAuthInvalidationStoreProvider =
    CustomAuthInvalidationStoreProvider._();

/// [CustomAuthInvalidationStore] のプロバイダ

final class CustomAuthInvalidationStoreProvider
    extends
        $FunctionalProvider<
          CustomAuthInvalidationStore,
          CustomAuthInvalidationStore,
          CustomAuthInvalidationStore
        >
    with $Provider<CustomAuthInvalidationStore> {
  /// [CustomAuthInvalidationStore] のプロバイダ
  CustomAuthInvalidationStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customAuthInvalidationStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customAuthInvalidationStoreHash();

  @$internal
  @override
  $ProviderElement<CustomAuthInvalidationStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomAuthInvalidationStore create(Ref ref) {
    return customAuthInvalidationStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomAuthInvalidationStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomAuthInvalidationStore>(value),
    );
  }
}

String _$customAuthInvalidationStoreHash() =>
    r'b543c32bb1a7562693017157d234a2e5f804d875';
