// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// データベースの接続（Executor）を提供するプロバイダー
///
/// このプロバイダーを差し替えることで、実機ではファイル、テストではメモリDBといった
/// 切り替えが容易になります。

@ProviderFor(databaseExecutor)
final databaseExecutorProvider = DatabaseExecutorProvider._();

/// データベースの接続（Executor）を提供するプロバイダー
///
/// このプロバイダーを差し替えることで、実機ではファイル、テストではメモリDBといった
/// 切り替えが容易になります。

final class DatabaseExecutorProvider
    extends $FunctionalProvider<QueryExecutor, QueryExecutor, QueryExecutor>
    with $Provider<QueryExecutor> {
  /// データベースの接続（Executor）を提供するプロバイダー
  ///
  /// このプロバイダーを差し替えることで、実機ではファイル、テストではメモリDBといった
  /// 切り替えが容易になります。
  DatabaseExecutorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseExecutorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseExecutorHash();

  @$internal
  @override
  $ProviderElement<QueryExecutor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QueryExecutor create(Ref ref) {
    return databaseExecutor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QueryExecutor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QueryExecutor>(value),
    );
  }
}

String _$databaseExecutorHash() => r'8465783d1eb5fca7d94ce4a3414689d7f8f4d976';

/// アプリ全体で共有するデータベース（AppDatabase）を提供するプロバイダー

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// アプリ全体で共有するデータベース（AppDatabase）を提供するプロバイダー

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// アプリ全体で共有するデータベース（AppDatabase）を提供するプロバイダー
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'e3b3be4c2c986d797347f3790a3d2c40dc6a2e04';
