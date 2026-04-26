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
///
/// 【運用ルール】
/// - `talker.handle()`: Crashlytics に「非致命的エラー (Non-fatal)」として自動送信されます。
/// - `talker.error()` など: ログ出力のみで Crashlytics には送信されません。
///   （グローバルな Fatal エラーとして手動で Crashlytics に送る場合はこちらを使用します）
class CustomTalkerObserver extends TalkerObserver {
  /// コンストラクタ
  CustomTalkerObserver({
    required this.isProd,
    required this.recordError,
  });

  /// 本番環境かどうか
  final bool isProd;

  /// 外部から送信処理を注入できるようにする
  final Future<void> Function(
    dynamic error,
    StackTrace? stackTrace, {
    required bool fatal,
  })
  recordError;

  @override
  void onError(TalkerError err) {
    super.onError(err);
    if (isProd) {
      unawaited(recordError(err.error, err.stackTrace, fatal: false));
    }
  }

  @override
  void onException(TalkerException err) {
    super.onException(err);
    if (isProd) {
      unawaited(recordError(err.exception, err.stackTrace, fatal: false));
    }
  }
}
