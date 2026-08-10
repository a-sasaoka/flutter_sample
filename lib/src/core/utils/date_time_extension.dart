import 'package:intl/intl.dart';

/// DateTime の拡張メソッド
extension DateTimeExtension on DateTime {
  /// 端末の言語設定（ロケール）に合わせた日付形式の文字列に変換する
  String toFormattedString([String? locale]) {
    return DateFormat.yMd(locale).add_Hm().format(this);
  }

  /// OSから自動取得したタイムゾーン（時差オフセットおよび時差名）を含むフォーマット文字列を生成する
  ///
  /// 出力例: `2026-08-11 07:30 (Timezone: +09:00, JST)`
  String toFormattedStringWithTimezone() {
    final year = this.year.toString().padLeft(4, '0');
    final month = this.month.toString().padLeft(2, '0');
    final day = this.day.toString().padLeft(2, '0');
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');

    final offset = timeZoneOffset;
    final offsetSign = offset.isNegative ? '-' : '+';
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (offset.inMinutes.abs() % 60).toString().padLeft(
      2,
      '0',
    );
    final offsetString = '$offsetSign$offsetHours:$offsetMinutes';

    return '$year-$month-$day $hour:$minute '
        '(Timezone: $offsetString, $timeZoneName)';
  }
}
