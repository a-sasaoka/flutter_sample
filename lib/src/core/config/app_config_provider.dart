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
  final router = ref.watch(routerProvider);
  final theme = await ref.watch(themeModeProvider.future);
  final locale = await ref.watch(localeProvider.future);

  return (
    router: router,
    theme: theme,
    locale: locale,
  );
}
