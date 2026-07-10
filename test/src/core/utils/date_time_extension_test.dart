import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/date_time_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // intl パッケージの各ロケールの日付書式データを初期化します
  setUpAll(() async {
    await initializeDateFormatting('ja');
    await initializeDateFormatting('en');
  });

  group('DateTimeExtension テスト', () {
    final testDate = DateTime(2026, 7, 11, 8, 9);

    test('【正常系】ロケールに「ja」を指定した場合、日本語形式（YYYY/MM/DD H:mm）で出力されること', () {
      final formatted = testDate.toFormattedString('ja');
      check(formatted).equals('2026/7/11 8:09');
    });

    test('【正常系】ロケールに「en」を指定した場合、英語形式（M/D/YYYY H:mm）で出力されること', () {
      final formatted = testDate.toFormattedString('en');
      check(formatted).equals('7/11/2026 08:09');
    });

    test('【正常系】引数を省略した場合でも、デフォルトの形式で例外なく文字列が出力されること', () {
      final formatted = testDate.toFormattedString();
      check(formatted).isNotEmpty();
    });
  });
}
