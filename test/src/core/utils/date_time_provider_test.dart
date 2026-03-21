import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // groupを使って、関連するテストをひとまとめにします
  group('currentDateTimeProvider テスト', () {
    test('デフォルトでは現在時刻（DateTime）を返すこと', () {
      // 1. Riverpodのプロバイダーを管理する空の箱（コンテナ）を作成
      final container = ProviderContainer();

      // テスト終了後にコンテナを破棄する（メモリリーク防止のベストプラクティス）
      addTearDown(container.dispose);

      // 2. プロバイダーから値を読み取る
      final dateTime = container.read(currentDateTimeProvider);

      // 3. 現在日時を保存
      final now = DateTime.now();

      // 3. 結果の検証（Assertion）
      expect(dateTime, isA<DateTime>()); // DateTime型であること
      // テスト実行時の現在時刻との誤差が1秒未満であること
      expect(now.difference(dateTime).inSeconds, lessThan(1));
    });

    test('overrideWithValue で任意の時間を注入（DI）できること', () {
      // 1. テスト用の固定された時間（モック）を用意
      final mockDate = DateTime(2024, 1, 1, 12);

      // 2. コンテナ作成時に、プロバイダーの値をモックに「上書き（override）」する！
      final container = ProviderContainer(
        overrides: [
          currentDateTimeProvider.overrideWithValue(mockDate),
        ],
      );
      addTearDown(container.dispose);

      // 3. プロバイダーから値を読み取る
      final dateTime = container.read(currentDateTimeProvider);

      // 4. 結果の検証（値がモックの日時と完全に一致すること）
      expect(dateTime, equals(mockDate));
    });
  });
}
