import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_sample/src/core/performance/firebase_performance_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'firebase_performance_dio_interceptor.g.dart';

/// Dio 通信のレイテンシやデータ転送量を自動計測するインターセプター
class FirebasePerformanceDioInterceptor extends Interceptor {
  /// コンストラクタ
  const FirebasePerformanceDioInterceptor({
    required this.performance,
    required this.talker,
  });

  /// Firebase Performance インスタンス（null の場合は計測を安全にスキップ）
  final FirebasePerformance? performance;

  /// ロガー
  final Talker talker;

  static const _metricKey = '_firebase_performance_metric';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final perf = performance;
    if (perf != null) {
      try {
        final uri = options.uri;
        final method = switch (options.method.toUpperCase()) {
          'GET' => HttpMethod.Get,
          'POST' => HttpMethod.Post,
          'PUT' => HttpMethod.Put,
          'DELETE' => HttpMethod.Delete,
          'HEAD' => HttpMethod.Head,
          'PATCH' => HttpMethod.Patch,
          'OPTIONS' => HttpMethod.Options,
          'TRACE' => HttpMethod.Trace,
          'CONNECT' => HttpMethod.Connect,
          _ => null,
        };

        if (method != null) {
          final metric = perf.newHttpMetric(uri.toString(), method);
          await metric.start();
          options.extra[_metricKey] = metric;
          if (_calculatePayloadSize(options.data) case final int size) {
            metric.requestPayloadSize = size;
          }
        }
      } on Object catch (e, st) {
        talker.handle(e, st, 'Failed to start HttpMetric on request');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      if (response.requestOptions.extra[_metricKey]
          case final HttpMetric metric) {
        try {
          _populateResponseInfo(metric, response);
        } finally {
          await metric.stop();
        }
      }
    } on Object catch (e, st) {
      talker.handle(e, st, 'Failed to stop HttpMetric on response');
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      if (err.requestOptions.extra[_metricKey] case final HttpMetric metric) {
        try {
          if (err.response case final Response<dynamic> response) {
            _populateResponseInfo(metric, response);
          }
        } finally {
          await metric.stop();
        }
      }
    } on Object catch (e, st) {
      talker.handle(e, st, 'Failed to stop HttpMetric on error');
    }
    handler.next(err);
  }

  /// レスポンス情報（ステータスコード、ContentType、サイズ）を HttpMetric に設定
  static void _populateResponseInfo(
    HttpMetric metric,
    Response<dynamic> response,
  ) {
    final contentType = response.headers.value(Headers.contentTypeHeader);
    metric
      ..httpResponseCode = response.statusCode
      ..responseContentType = contentType;
    if (_calculateResponsePayloadSize(response, contentType)
        case final int size) {
      metric.responsePayloadSize = size;
    } else if (response.headers.value(Headers.contentLengthHeader)
        case final String lengthStr when int.tryParse(lengthStr) != null) {
      metric.responsePayloadSize = int.parse(lengthStr);
    }
  }

  /// レスポンスデータのバイトサイズ（UTF-8）を計算
  static int? _calculateResponsePayloadSize(
    Response<dynamic> response,
    String? contentType,
  ) {
    final data = response.data;
    if (data == null) {
      return null;
    }
    if (data is String) {
      final isJson =
          response.requestOptions.responseType == ResponseType.json ||
          (contentType != null && contentType.contains('application/json'));
      if (isJson &&
          response.requestOptions.responseType != ResponseType.plain) {
        return utf8.encode(jsonEncode(data)).length;
      }
      return utf8.encode(data).length;
    }
    return _calculatePayloadSize(data);
  }

  /// ペイロードのバイトサイズ（UTF-8）を計算
  static int? _calculatePayloadSize(dynamic data) {
    if (data == null) {
      return null;
    }
    return switch (data) {
      final List<int> bytes => bytes.length,
      final String text => utf8.encode(text).length,
      final Map<dynamic, dynamic> map => _encodeJsonLength(map),
      final List<dynamic> list => _encodeJsonLength(list),
      final FormData formData => formData.length >= 0 ? formData.length : null,
      _ => null,
    };
  }

  /// JSON オブジェクトのシリアライズ後 UTF-8 バイト数を計算
  static int? _encodeJsonLength(Object jsonObject) {
    try {
      return utf8.encode(jsonEncode(jsonObject)).length;
    } on Object {
      return null;
    }
  }
}

/// FirebasePerformanceDioInterceptor を提供するプロバイダー
@Riverpod(keepAlive: true)
FirebasePerformanceDioInterceptor firebasePerformanceDioInterceptor(Ref ref) {
  return FirebasePerformanceDioInterceptor(
    performance: ref.watch(firebasePerformanceProvider),
    talker: ref.watch(loggerProvider),
  );
}
