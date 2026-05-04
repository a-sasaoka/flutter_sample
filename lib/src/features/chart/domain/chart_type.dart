import 'package:flutter_sample/l10n/app_localizations.dart';

/// グラフの種類を定義する列挙型
enum ChartType {
  /// 折れ線グラフ
  line,

  /// 棒グラフ
  bar,

  /// 円グラフ
  pie;

  /// 画面に表示するローカライズされた名前
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ChartType.line:
        return l10n.chartLine;
      case ChartType.bar:
        return l10n.chartBar;
      case ChartType.pie:
        return l10n.chartPie;
    }
  }
}
