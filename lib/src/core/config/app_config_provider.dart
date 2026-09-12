import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config_provider.g.dart';

/// アプリ全体の設定をまとめて取得するプロバイダ
@Riverpod(keepAlive: true)
Future<
  ({
    GoRouter router,
    ThemeMode themeMode,
    ThemeData lightTheme,
    ThemeData darkTheme,
    Locale? locale,
  })
>
appConfig(
  Ref ref,
) async {
  // 同期プロバイダ → 即取得
  final router = ref.watch(routerProvider);

  // 3つの Future を並列で処理
  final (themeMode, locale, scheme) = await (
    ref.watch(themeModeProvider.future),
    ref.watch(localeProvider.future),
    ref.watch(themeSchemeProvider.future),
  ).wait;

  // 名前付き Record を返す
  return (
    router: router,
    themeMode: themeMode,
    lightTheme: AppTheme.light(scheme),
    darkTheme: AppTheme.dark(scheme),
    locale: locale,
  );
}
