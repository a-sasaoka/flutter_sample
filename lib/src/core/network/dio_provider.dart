import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'dio_provider.g.dart';

/// 追加の認証インターセプターを提供するプロバイダー（デフォルトは空リスト）
/// Core層では特定の機能に依存しないため、App/Feature層にてオーバーライドして注入します
@Riverpod(keepAlive: true)
List<Interceptor> authInterceptors(Ref ref) {
  return const [];
}

/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - トークン認証などもオーバーライドによって組み込み可能
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return _createDio(
    ref,
    additionalInterceptors: ref.watch(authInterceptorsProvider),
  );
}

/// 認証や再リクエスト用のプレーンなDioインスタンスを提供するProvider
///
/// メインの `dioProvider` と同じ基本設定・ログ出力を適用しますが、
/// 無限ループを防ぐためトークンのインターセプターは含まれません。
@Riverpod(keepAlive: true)
Dio baseDio(Ref ref) {
  return _createDio(ref);
}

/// Dioのインスタンス作成と共通設定を一括で行うヘルパー
Dio _createDio(
  Ref ref, {
  List<Interceptor> additionalInterceptors = const [],
}) {
  final config = ref.watch(envConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: Duration(seconds: config.connectTimeout),
      receiveTimeout: Duration(seconds: config.receiveTimeout),
      sendTimeout: Duration(seconds: config.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // 1. 追加のインターセプター（トークン付与など）があれば先に追加
  if (additionalInterceptors.isNotEmpty) {
    dio.interceptors.addAll(additionalInterceptors);
  }

  // 2. 共通のエラー変換・簡易ログインターセプターを追加
  dio.interceptors.add(ref.watch(dioInterceptorProvider));

  // 3. 開発時のみ詳細なログインターセプターを追加
  if (kDebugMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        talker: ref.watch(loggerProvider),
        settings: TalkerDioLoggerSettings(
          printRequestHeaders: true,
          errorPen: AnsiPen()..red(),
          requestPen: AnsiPen()..yellow(),
          responsePen: AnsiPen()..green(),
        ),
      ),
    );
  }

  return dio;
}
