// lib/src/core/config/app_theme.dart
// FlexColorScheme を使った Material 3 対応テーマ。
// 初心者向けポイント：light/dark の2種類を用意し、MaterialAppに両方渡します。

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// アプリ全体のテーマ設定をまとめたクラス
class AppTheme {
  AppTheme._();

  /// ライトテーマ
  static ThemeData light() {
    return FlexThemeData.light(
      scheme: FlexScheme.indigoM3, // プリセットを使う or …
      // ↓ シード色から自動生成したカラースキームを使いたいときは下記でもOK
      // colorScheme: SeedColorScheme.fromSeeds(
      //   primaryKey: _seed,
      //   brightness: Brightness.light,
      // ),
      subThemesData: const FlexSubThemesData(
        defaultRadius: 14, // 角丸を統一
        filledButtonRadius: 14,
        useMaterial3Typography: true,
      ),
      visualDensity: VisualDensity.standard,
      // アプリ全体の細かいトーン調整が必要なら下記で追記
      // typography: Typography.material2021(),
    );
  }

  /// ダークテーマ
  static ThemeData dark() {
    return FlexThemeData.dark(
      scheme: FlexScheme.indigoM3,
      // colorScheme: SeedColorScheme.fromSeeds(
      //   primaryKey: _seed,
      //   brightness: Brightness.dark,
      // ),
      subThemesData: const FlexSubThemesData(
        defaultRadius: 14,
        filledButtonRadius: 14,
        useMaterial3Typography: true,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
