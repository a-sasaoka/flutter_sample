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
      primaryTextTheme: AppTheme.light().primaryTextTheme.apply(
        fontFamily: 'NotoSansJP',
      ),
      chipTheme: AppTheme.light().chipTheme.copyWith(
        labelStyle:
            AppTheme.light().chipTheme.labelStyle?.copyWith(
              fontFamily: 'NotoSansJP',
            ) ??
            const TextStyle(fontFamily: 'NotoSansJP'),
        secondaryLabelStyle:
            AppTheme.light().chipTheme.secondaryLabelStyle?.copyWith(
              fontFamily: 'NotoSansJP',
            ) ??
            const TextStyle(fontFamily: 'NotoSansJP'),
      ),
    ),
    darkTheme: AppTheme.dark().copyWith(
      textTheme: AppTheme.dark().textTheme.apply(
        fontFamily: 'NotoSansJP',
      ),
      primaryTextTheme: AppTheme.dark().primaryTextTheme.apply(
        fontFamily: 'NotoSansJP',
      ),
      chipTheme: AppTheme.dark().chipTheme.copyWith(
        labelStyle:
            AppTheme.dark().chipTheme.labelStyle?.copyWith(
              fontFamily: 'NotoSansJP',
            ) ??
            const TextStyle(fontFamily: 'NotoSansJP'),
        secondaryLabelStyle:
            AppTheme.dark().chipTheme.secondaryLabelStyle?.copyWith(
              fontFamily: 'NotoSansJP',
            ) ??
            const TextStyle(fontFamily: 'NotoSansJP'),
      ),
    ),
    themeMode: themeMode,
    localizationsDelegates: [
      if (additionalDelegates != null) ...additionalDelegates,
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: home,
    debugShowCheckedModeBanner: false,
  );
}
