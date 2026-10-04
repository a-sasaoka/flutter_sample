// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリがロック解除済み（操作可能状態）かどうかを提供するプロバイダー
///
/// デフォルト実装は、Core層が特定機能に依存せず動作できるよう `true`（ロックなし）を返します。
/// アプリ起動時に `appLockOverrides` 等を通じて、実際のアプリロック状態と同期するようにオーバーライドされます。

@ProviderFor(isAppUnlocked)
final isAppUnlockedProvider = IsAppUnlockedProvider._();

/// アプリがロック解除済み（操作可能状態）かどうかを提供するプロバイダー
///
/// デフォルト実装は、Core層が特定機能に依存せず動作できるよう `true`（ロックなし）を返します。
/// アプリ起動時に `appLockOverrides` 等を通じて、実際のアプリロック状態と同期するようにオーバーライドされます。

final class IsAppUnlockedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// アプリがロック解除済み（操作可能状態）かどうかを提供するプロバイダー
  ///
  /// デフォルト実装は、Core層が特定機能に依存せず動作できるよう `true`（ロックなし）を返します。
  /// アプリ起動時に `appLockOverrides` 等を通じて、実際のアプリロック状態と同期するようにオーバーライドされます。
  IsAppUnlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAppUnlockedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAppUnlockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAppUnlocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAppUnlockedHash() => r'433dd0b735588b0a173dae16d062a621806756f9';
