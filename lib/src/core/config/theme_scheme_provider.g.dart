// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_scheme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🎨 テーマカラー（カラースキーム）の状態を管理・保存するプロバイダー

@ProviderFor(ThemeSchemeNotifier)
final themeSchemeProvider = ThemeSchemeNotifierProvider._();

/// 🎨 テーマカラー（カラースキーム）の状態を管理・保存するプロバイダー
final class ThemeSchemeNotifierProvider
    extends $AsyncNotifierProvider<ThemeSchemeNotifier, FlexScheme> {
  /// 🎨 テーマカラー（カラースキーム）の状態を管理・保存するプロバイダー
  ThemeSchemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeSchemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSchemeNotifierHash();

  @$internal
  @override
  ThemeSchemeNotifier create() => ThemeSchemeNotifier();
}

String _$themeSchemeNotifierHash() =>
    r'f26146c278a79ce96c02b77b75c44d3524ff830c';

/// 🎨 テーマカラー（カラースキーム）の状態を管理・保存するプロバイダー

abstract class _$ThemeSchemeNotifier extends $AsyncNotifier<FlexScheme> {
  FutureOr<FlexScheme> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FlexScheme>, FlexScheme>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FlexScheme>, FlexScheme>,
              AsyncValue<FlexScheme>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
