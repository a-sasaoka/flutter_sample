import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('clockProvider テスト', () {
    test('デフォルトの clockProvider が現在の時刻に近い値を返すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final clock = container.read(clockProvider);
      final now = DateTime.now();
      final clockNow = clock();

      // 数ミリ秒の誤差は許容する
      expect(
        clockNow.difference(now).inMilliseconds.abs(),
        lessThan(100),
      );
    });

    test('clockProvider を関数のモックで上書きできること', () {
      final mockDate = DateTime(2026, 5, 10);
      final container = ProviderContainer(
        overrides: [
          // 関数を返すプロバイダを、固定値を返す関数で上書き！
          clockProvider.overrideWithValue(() => mockDate),
        ],
      );
      addTearDown(container.dispose);

      final clock = container.read(clockProvider);
      expect(clock(), mockDate);
    });
  });
}
