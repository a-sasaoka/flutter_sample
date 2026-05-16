// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SharedPreferencesAsync をアプリ全体で共有する Provider
///
/// - 非同期で安全に利用可能
/// - 起動時に待ち時間が発生しない
/// - テスト時に差し替えやすい

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// SharedPreferencesAsync をアプリ全体で共有する Provider
///
/// - 非同期で安全に利用可能
/// - 起動時に待ち時間が発生しない
/// - テスト時に差し替えやすい

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferencesAsync,
          SharedPreferencesAsync,
          SharedPreferencesAsync
        >
    with $Provider<SharedPreferencesAsync> {
  /// SharedPreferencesAsync をアプリ全体で共有する Provider
  ///
  /// - 非同期で安全に利用可能
  /// - 起動時に待ち時間が発生しない
  /// - テスト時に差し替えやすい
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferencesAsync> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferencesAsync create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferencesAsync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferencesAsync>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'27f75883fdfa5699515101e124521cad2de328e6';
