// FlexColorScheme を使った Material 3 対応テーマ。
// 初心者向けポイント：light/dark の2種類を用意し、MaterialAppに両方渡します。

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// アプリ全体のテーマ設定をまとめたクラス
class AppTheme {
  AppTheme._(); // coverage:ignore-line

  // ベースとなる色（お好みでOK）
  // static const _seed = Color(0xFF4F46E5); // indigo-ish

  // 共通のカラースキーム設定
  static const FlexScheme _scheme = FlexScheme.indigoM3;

  // 共通のサブテーマ設定
  static const FlexSubThemesData _subThemesData = FlexSubThemesData(
    defaultRadius: 14, // 角丸を統一
    filledButtonRadius: 14,
    useMaterial3Typography: true,
  );

  /// ライトテーマ
  static ThemeData light() {
    return FlexThemeData.light(
      scheme: _scheme, // プリセットを使う or …
      // ↓ シード色から自動生成したカラースキームを使いたいときは下記でもOK
      // colorScheme: SeedColorScheme.fromSeeds(
      //   primaryKey: _seed,
      //   brightness: Brightness.light,
      // ),
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.standard,
      // アプリ全体の細かいトーン調整が必要なら下記で追記
      // typography: Typography.material2021(),
    );
  }

  /// ダークテーマ
  static ThemeData dark() {
    return FlexThemeData.dark(
      scheme: _scheme,
      // colorScheme: SeedColorScheme.fromSeeds(
      //   primaryKey: _seed,
      //   brightness: Brightness.dark,
      // ),
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.standard,
    );
  }
}
