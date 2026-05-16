import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/drift_talker_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// データベースの接続（Executor）を提供するプロバイダー
///
/// このプロバイダーを差し替えることで、実機ではファイル、テストではメモリDBといった
/// 切り替えが容易になります。
@Riverpod(keepAlive: true)
QueryExecutor databaseExecutor(Ref ref) {
  final talker = ref.watch(loggerProvider);

  // Talkerによるログ出力（実行時間計測・エラー詳細）を有効にした接続を作成
  return driftDatabase(name: 'my_app_db').interceptWith(
    DriftTalkerInterceptor(talker),
  );
}

/// アプリ全体で共有するデータベース（AppDatabase）を提供するプロバイダー
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final executor = ref.watch(databaseExecutorProvider);
  final db = AppDatabase(executor);

  // プロバイダーが破棄された際（アプリ終了やテスト時など）に、データベースの接続を適切に閉じる
  ref.onDispose(db.close);
  return db;
}
