import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';

/// ゴールデンテスト用の共通 MaterialApp 構成を提供するヘルパー関数
Widget buildGoldenTestApp({
  required Widget home,
  required ThemeMode themeMode,
  List<LocalizationsDelegate<dynamic>>? additionalDelegates,
}) {
  return MaterialApp(
    // 日本語フォントを適用したテーマを設定します
    theme: AppTheme.light().copyWith(
      textTheme: AppTheme.light().textTheme.apply(
        fontFamily: 'NotoSansJP',
      ),
    ),
    darkTheme: AppTheme.dark().copyWith(
      textTheme: AppTheme.dark().textTheme.apply(
        fontFamily: 'NotoSansJP',
      ),
    ),
    themeMode: themeMode,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      if (additionalDelegates != null) ...additionalDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: home,
    debugShowCheckedModeBanner: false,
  );
}
