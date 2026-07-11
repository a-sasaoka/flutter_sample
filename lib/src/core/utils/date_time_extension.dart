import 'package:intl/intl.dart';

/// DateTime の拡張メソッド
extension DateTimeExtension on DateTime {
  /// 端末の言語設定（ロケール）に合わせた日付形式の文字列に変換する
  String toFormattedString([String? locale]) {
    return DateFormat.yMd(locale).add_Hm().format(this);
  }
}
