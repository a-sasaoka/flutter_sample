import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_sample/src/core/performance/firebase_performance_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'performance_service.g.dart';

/// アプリのパフォーマンス計測（カスタムトレース）を提供するサービス
class PerformanceService {
  /// コンストラクタ
  const PerformanceService({
    required this.performance,
    required this.talker,
  });

  /// Firebase Performance インスタンス（null の場合は計測を安全にスキップ）
  final FirebasePerformance? performance;

  /// ロガー
  final Talker talker;

  /// 任意の非同期処理の実行時間をカスタムトレースとして計測
  ///
  /// - [traceName]: 計測対象のトレース名
  /// - [action]: 計測する処理本体
  /// - [attributes]: トレースに付与するカスタム属性
  /// - [metrics]: トレースに付与するカスタム数値メトリクス
  Future<T> traceExecution<T>({
    required String traceName,
    required Future<T> Function() action,
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final perf = performance;
    if (perf == null) {
      return action();
    }

    Trace? trace;
    var isStarted = false;
    try {
      trace = perf.newTrace(traceName);
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      if (metrics != null) {
        for (final entry in metrics.entries) {
          trace.setMetric(entry.key, entry.value);
        }
      }
      await trace.start();
      isStarted = true;
    } on Object catch (e, st) {
      talker.handle(e, st, 'Failed to start performance trace: $traceName');
    }

    try {
      return await action();
    } finally {
      if (trace != null && isStarted) {
        try {
          await trace.stop();
          talker.debug('⚡️ Performance trace finished: $traceName');
        } on Object catch (e, st) {
          talker.handle(e, st, 'Failed to stop performance trace: $traceName');
        }
      }
    }
  }
}

/// PerformanceService を提供するプロバイダー
@Riverpod(keepAlive: true)
PerformanceService performanceService(Ref ref) {
  return PerformanceService(
    performance: ref.watch(firebasePerformanceProvider),
    talker: ref.watch(loggerProvider),
  );
}
