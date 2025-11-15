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
const sharedPreferencesProvider = SharedPreferencesProvider._();

/// SharedPreferencesAsync をアプリ全体で共有する Provider
///
/// - 非同期で安全に利用可能
/// - 起動時に待ち時間が発生しない
/// - テスト時に差し替えやすい

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferencesAsync>,
          SharedPreferencesAsync,
          FutureOr<SharedPreferencesAsync>
        >
    with
        $FutureModifier<SharedPreferencesAsync>,
        $FutureProvider<SharedPreferencesAsync> {
  /// SharedPreferencesAsync をアプリ全体で共有する Provider
  ///
  /// - 非同期で安全に利用可能
  /// - 起動時に待ち時間が発生しない
  /// - テスト時に差し替えやすい
  const SharedPreferencesProvider._()
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
  $FutureProviderElement<SharedPreferencesAsync> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferencesAsync> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'cd881b133554c44e76bebc53d340b7dc2ec8f01a';
