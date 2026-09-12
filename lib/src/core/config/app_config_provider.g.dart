// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリ全体の設定をまとめて取得するプロバイダ

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// アプリ全体の設定をまとめて取得するプロバイダ

final class AppConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            ({
              ThemeData darkTheme,
              ThemeData lightTheme,
              Locale? locale,
              GoRouter router,
              ThemeMode themeMode,
            })
          >,
          ({
            ThemeData darkTheme,
            ThemeData lightTheme,
            Locale? locale,
            GoRouter router,
            ThemeMode themeMode,
          }),
          FutureOr<
            ({
              ThemeData darkTheme,
              ThemeData lightTheme,
              Locale? locale,
              GoRouter router,
              ThemeMode themeMode,
            })
          >
        >
    with
        $FutureModifier<
          ({
            ThemeData darkTheme,
            ThemeData lightTheme,
            Locale? locale,
            GoRouter router,
            ThemeMode themeMode,
          })
        >,
        $FutureProvider<
          ({
            ThemeData darkTheme,
            ThemeData lightTheme,
            Locale? locale,
            GoRouter router,
            ThemeMode themeMode,
          })
        > {
  /// アプリ全体の設定をまとめて取得するプロバイダ
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $FutureProviderElement<
    ({
      ThemeData darkTheme,
      ThemeData lightTheme,
      Locale? locale,
      GoRouter router,
      ThemeMode themeMode,
    })
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<
    ({
      ThemeData darkTheme,
      ThemeData lightTheme,
      Locale? locale,
      GoRouter router,
      ThemeMode themeMode,
    })
  >
  create(Ref ref) {
    return appConfig(ref);
  }
}

String _$appConfigHash() => r'0f3a3f98a2c4480b964563844e60e7a96f9f9829';
