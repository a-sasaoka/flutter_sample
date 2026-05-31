import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEvent テスト', () {
    test('定義されているAnalyticsイベントの数が正確に5つであること', () {
      check(AnalyticsEvent.values.length).equals(5);
    });

    test('各enumが正しいイベント名(文字列)を保持していること', () {
      check(AnalyticsEvent.appStarted.name).equals('app_started');
      check(
        AnalyticsEvent.homeButtonTapped.name,
      ).equals('home_analytics_button_tapped');
      check(AnalyticsEvent.loginSuccess.name).equals('login_success');
      check(AnalyticsEvent.logout.name).equals('logout');
      check(AnalyticsEvent.errorOccurred.name).equals('error_occurred');
    });
  });
}
