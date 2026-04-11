import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

// coverage:ignore-start
/// Firebase Analytics のインスタンスを提供する Provider
@riverpod
FirebaseAnalytics firebaseAnalytics(Ref ref) {
  return FirebaseAnalytics.instance;
}
// coverage:ignore-end

/// Analytics Service を Riverpod で提供
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService(
    ref,
    firebaseAnalytics: ref.watch(firebaseAnalyticsProvider),
  );
}

/// Analytics Service
class AnalyticsService {
  /// コンストラクタ
  AnalyticsService(this._ref, {required FirebaseAnalytics firebaseAnalytics})
    : _firebaseAnalytics = firebaseAnalytics;

  final Ref _ref;
  final FirebaseAnalytics _firebaseAnalytics;

  /// 汎用イベント送信（timestamp 自動付与）
  Future<void> logEvent({
    required AnalyticsEvent event,
    Map<String, Object?> parameters = const {},
  }) async {
    final data = <String, Object>{
      for (final entry in parameters.entries)
        if (entry.value != null) entry.key: entry.value!,
      'timestamp': _ref.read(currentDateTimeProvider).millisecondsSinceEpoch,
    };

    try {
      await _firebaseAnalytics.logEvent(
        name: event.name,
        parameters: data,
      );
    } on Exception catch (e) {
      // 分析イベントの送信失敗でアプリのクラッシュや機能停止を防ぐ
      _ref.read(loggerProvider).w('Analytics Error: $e');
    }
  }
}
