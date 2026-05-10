import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    firebaseAnalytics: ref.watch(firebaseAnalyticsProvider),
    talker: ref.watch(loggerProvider),
    getCurrentDateTime: ref.watch(clockProvider),
  );
}

/// Analytics Service
class AnalyticsService {
  /// コンストラクタ
  AnalyticsService({
    required FirebaseAnalytics firebaseAnalytics,
    required Talker talker,
    required DateTime Function() getCurrentDateTime,
  }) : _firebaseAnalytics = firebaseAnalytics,
       _talker = talker,
       _getCurrentDateTime = getCurrentDateTime;

  final FirebaseAnalytics _firebaseAnalytics;
  final Talker _talker;
  final DateTime Function() _getCurrentDateTime;

  /// 汎用イベント送信（timestamp 自動付与）
  Future<void> logEvent({
    required AnalyticsEvent event,
    Map<String, Object?> parameters = const {},
  }) async {
    final data = <String, Object>{
      for (final entry in parameters.entries)
        if (entry.value != null) entry.key: entry.value!,
      'timestamp': _getCurrentDateTime().millisecondsSinceEpoch,
    };

    try {
      await _firebaseAnalytics.logEvent(
        name: event.name,
        parameters: data,
      );
    } on Exception catch (e) {
      // 分析イベントの送信失敗でアプリのクラッシュや機能停止を防ぐ
      _talker.warning('Analytics Error: $e');
    }
  }

  /// ユーザーIDを設定する
  ///
  /// ログイン時や起動時に呼び出し、「誰が」操作しているかを紐付けます。
  /// ログアウト時は null を渡してクリアします。
  Future<void> setUserId(String? id) async {
    try {
      await _firebaseAnalytics.setUserId(id: id);
    } on Exception catch (e) {
      _talker.warning('Analytics SetUserId Error: $e');
    }
  }

  /// ユーザープロパティ（会員ランクなど）を設定する
  ///
  /// [name] は Firebase Console で登録した名前を指定します。
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _firebaseAnalytics.setUserProperty(name: name, value: value);
    } on Exception catch (e) {
      _talker.warning('Analytics SetUserProperty Error: $e');
    }
  }
}
