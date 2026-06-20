import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// アプリ全体のテーマ設定をまとめたクラス
abstract final class AppTheme {
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

  /// グラフ用カラー（ライトモード）
  static const List<Color> _lightChartColors = [
    Color(0xFF4F46E5), // 藍色
    Color(0xFF10B981), // 緑色
    Color(0xFFF59E0B), // 橙色
    Color(0xFFF43F5E), // 桃色
    Color(0xFF8B5CF6), // 紫色
    Color(0xFF0EA5E9), // 水色
  ];

  /// グラフ用カラー（ダークモード）
  static const List<Color> _darkChartColors = [
    Color(0xFF818CF8), // 藍色（明）
    Color(0xFF34D399), // 緑色（明）
    Color(0xFFFBBF24), // 橙色（明）
    Color(0xFFFB7185), // 桃色（明）
    Color(0xFFA78BFA), // 紫色（明）
    Color(0xFF38BDF8), // 水色（明）
  ];

  /// 現在のテーマの明るさに応じて、統一されたグラフ用カラーパレットを返す
  static List<Color> chartColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkChartColors : _lightChartColors;
  }

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
