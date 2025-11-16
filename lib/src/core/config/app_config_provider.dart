import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config_provider.g.dart';

/// アプリ全体の設定をまとめて取得するプロバイダ
@riverpod
Future<({GoRouter router, ThemeMode theme, Locale? locale})> appConfig(
  Ref ref,
) async {
  // 同期プロバイダ → 即取得
  final router = ref.watch(routerProvider);

  // 2つの Future を並列で処理
  final (theme, locale) = await (
    ref.watch(themeModeProvider.future),
    ref.watch(localeProvider.future),
  ).wait;

  // 名前付き Record を返す
  return (
    router: router,
    theme: theme,
    locale: locale,
  );
}
