// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリ全体の設定をまとめて取得するプロバイダ

@ProviderFor(appConfig)
const appConfigProvider = AppConfigProvider._();

/// アプリ全体の設定をまとめて取得するプロバイダ

final class AppConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<({Locale? locale, GoRouter router, ThemeMode theme})>,
          ({Locale? locale, GoRouter router, ThemeMode theme}),
          FutureOr<({Locale? locale, GoRouter router, ThemeMode theme})>
        >
    with
        $FutureModifier<({Locale? locale, GoRouter router, ThemeMode theme})>,
        $FutureProvider<({Locale? locale, GoRouter router, ThemeMode theme})> {
  /// アプリ全体の設定をまとめて取得するプロバイダ
  const AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $FutureProviderElement<({Locale? locale, GoRouter router, ThemeMode theme})>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({Locale? locale, GoRouter router, ThemeMode theme})> create(
    Ref ref,
  ) {
    return appConfig(ref);
  }
}

String _$appConfigHash() => r'db1b57dbca1851c6be2d6c2b5d442d57cb0be79d';
