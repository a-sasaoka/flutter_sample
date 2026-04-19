import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEvent テスト', () {
    test('定義されているAnalyticsイベントの数が正確に5つであること', () {
      expect(AnalyticsEvent.values.length, 5);
    });

    test('各enumが正しいイベント名(文字列)を保持していること', () {
      expect(AnalyticsEvent.appStarted.name, 'app_started');
      expect(
        AnalyticsEvent.homeButtonTapped.name,
        'home_analytics_button_tapped',
      );
      expect(AnalyticsEvent.loginSuccess.name, 'login_success');
      expect(AnalyticsEvent.logout.name, 'logout');
      expect(AnalyticsEvent.errorOccurred.name, 'error_occurred');
    });
  });
}
