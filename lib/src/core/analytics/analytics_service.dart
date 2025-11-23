import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

/// Analytics Service を Riverpod で提供
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
}

/// Analytics Service
class AnalyticsService {
  /// コンストラクタ
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  /// 汎用イベント送信（timestamp 自動付与）
  Future<void> logEvent({
    required AnalyticsEvent event,
    Map<String, Object?> parameters = const {},
  }) async {
    final data = {
      ...parameters,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _analytics.logEvent(
      name: event.name,
      parameters: data.cast<String, Object>(),
    );
  }
}
