/// DateTime の拡張メソッド
extension DateTimeExtension on DateTime {
  /// 「YYYY/MM/DD HH:mm」形式の文字列に変換する
  String toFormattedString() {
    return '$year/'
        '${month.toString().padLeft(2, '0')}/'
        '${day.toString().padLeft(2, '0')} '
        '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
