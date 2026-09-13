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
              TextScaler textScaler,
              ThemeMode themeMode,
            })
          >,
          ({
            ThemeData darkTheme,
            ThemeData lightTheme,
            Locale? locale,
            GoRouter router,
            TextScaler textScaler,
            ThemeMode themeMode,
          }),
          FutureOr<
            ({
              ThemeData darkTheme,
              ThemeData lightTheme,
              Locale? locale,
              GoRouter router,
              TextScaler textScaler,
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
            TextScaler textScaler,
            ThemeMode themeMode,
          })
        >,
        $FutureProvider<
          ({
            ThemeData darkTheme,
            ThemeData lightTheme,
            Locale? locale,
            GoRouter router,
            TextScaler textScaler,
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
      TextScaler textScaler,
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
      TextScaler textScaler,
      ThemeMode themeMode,
    })
  >
  create(Ref ref) {
    return appConfig(ref);
  }
}

String _$appConfigHash() => r'92bee40975adcb68718c708f5ff3cf69b1c96835';
