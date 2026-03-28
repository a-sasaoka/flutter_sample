import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

// FirebaseAnalytics のモック
class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

// Logger のモック
class MockLogger extends Mock implements Logger {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late MockLogger mockLogger;
  late ProviderContainer container;

  // テスト用の固定日時（時間を止める！）
  final mockDateTime = DateTime(2024, 1, 1, 12);

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    mockLogger = MockLogger();

    container = ProviderContainer(
      overrides: [
        // 1. Analyticsのモックを注入
        firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
        // 2. 現在日時を固定の日時に差し替え（DIの真骨頂！）
        currentDateTimeProvider.overrideWithValue(mockDateTime),
        // 3. Loggerをモック化（flavorProvider のエラー回避 & ログのノイズ軽減）
        loggerProvider.overrideWithValue(mockLogger),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AnalyticsService テスト', () {
    test('logEvent が正しいイベント名とパラメータ(null除外, 固定のtimestamp付与)で呼び出されること', () async {
      // Arrange
      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      final service = container.read(analyticsServiceProvider);

      // Act
      await service.logEvent(
        event: AnalyticsEvent.loginSuccess,
        parameters: {
          'user_id': 123,
          'user_type': 'premium',
          'null_value': null, // 除外対象
        },
      );

      // Assert
      final captured = verify(
        () => mockAnalytics.logEvent(
          name: captureAny(named: 'name'),
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured;

      expect(captured[0], 'login_success');

      final params = captured[1] as Map<String, Object>;

      // ① 正常な値が渡されているか
      expect(params['user_id'], 123);
      expect(params['user_type'], 'premium');

      // ② null の値が正しく除外されているか
      expect(params.containsKey('null_value'), isFalse);

      // ③ 【進化ポイント】timestamp がモックで固定した日時と「完全に一致」しているか！
      expect(params['timestamp'], mockDateTime.millisecondsSinceEpoch);
    });

    test('logEvent 実行時に例外が発生した場合、クラッシュせずに処理が完了すること', () async {
      // Arrange
      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async => throw Exception('Test Analytics Error'));

      final service = container.read(analyticsServiceProvider);

      // Act & Assert
      // 例外が内部で catch され、メソッドがエラーを外に漏らさず正常終了(completes)することを確認
      await expectLater(
        service.logEvent(event: AnalyticsEvent.loginSuccess),
        completes,
      );
    });
  });
}
