// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_suppression_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリロック一時停止ハンドラーを提供するプロバイダー
///
/// デフォルト実装は、Core層が特定機能に依存しないよう、処理をそのまま実行するNo-Op（透過的）関数を提供します。
/// アプリ起動時に `appLockOverrides` 等を通じて本実装がオーバーライドされます。

@ProviderFor(lockSuppressionRunner)
final lockSuppressionRunnerProvider = LockSuppressionRunnerProvider._();

/// アプリロック一時停止ハンドラーを提供するプロバイダー
///
/// デフォルト実装は、Core層が特定機能に依存しないよう、処理をそのまま実行するNo-Op（透過的）関数を提供します。
/// アプリ起動時に `appLockOverrides` 等を通じて本実装がオーバーライドされます。

final class LockSuppressionRunnerProvider
    extends
        $FunctionalProvider<
          LockSuppressionRunner,
          LockSuppressionRunner,
          LockSuppressionRunner
        >
    with $Provider<LockSuppressionRunner> {
  /// アプリロック一時停止ハンドラーを提供するプロバイダー
  ///
  /// デフォルト実装は、Core層が特定機能に依存しないよう、処理をそのまま実行するNo-Op（透過的）関数を提供します。
  /// アプリ起動時に `appLockOverrides` 等を通じて本実装がオーバーライドされます。
  LockSuppressionRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockSuppressionRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockSuppressionRunnerHash();

  @$internal
  @override
  $ProviderElement<LockSuppressionRunner> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LockSuppressionRunner create(Ref ref) {
    return lockSuppressionRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockSuppressionRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockSuppressionRunner>(value),
    );
  }
}

String _$lockSuppressionRunnerHash() =>
    r'7234493448aae8d70059de96eb8f9a0d5fe21255';
