import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'logger_provider.g.dart';

/// 統合ロギングプロバイダ (Talker)
@Riverpod(keepAlive: true)
Talker logger(Ref ref) {
  throw UnimplementedError();
}

/// Talker で検知したエラーを Crashlytics に送信するためのカスタムオブザーバー
class CustomTalkerObserver extends TalkerObserver {
  /// コンストラクタ
  CustomTalkerObserver({
    required this.isProd,
    required this.recordError,
  });

  /// 本番環境かどうか
  final bool isProd;

  /// 外部から送信処理を注入できるようにする
  final Future<void> Function(dynamic error, StackTrace? stackTrace)
  recordError;

  @override
  void onError(TalkerError err) {
    super.onError(err);
    if (isProd) {
      unawaited(recordError(err.error, err.stackTrace));
    }
  }

  @override
  void onException(TalkerException err) {
    super.onException(err);
    if (isProd) {
      unawaited(recordError(err.exception, err.stackTrace));
    }
  }
}
