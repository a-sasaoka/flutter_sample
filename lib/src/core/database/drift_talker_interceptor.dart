import 'package:drift/drift.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// DriftのクエリをTalkerでログ出力するためのインターセプター
///
/// クエリの実行時間の計測と、エラー発生時の詳細なログ出力を担当します。
class DriftTalkerInterceptor extends QueryInterceptor {
  /// コンストラクタ
  DriftTalkerInterceptor(this._talker);

  final Talker _talker;

  /// クエリ実行をラップしてログ出力する共通処理
  Future<T> _run<T>(
    String method,
    String statement,
    List<Object?> args,
    Future<T> Function() action,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      sw.stop();
      _talker.debug(
        '[Drift] $method (${sw.elapsedMilliseconds}ms): '
        '$statement | Args: $args',
      );
      return result;
    } on Exception catch (e, st) {
      sw.stop();
      _talker.error(
        '[Drift] $method Error after ${sw.elapsedMilliseconds}ms: '
        '$statement | Args: $args',
        e,
        st,
      );
      rethrow;
    }
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'Custom',
      statement,
      args,
      () => executor.runCustom(statement, args),
    );
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'Insert',
      statement,
      args,
      () => executor.runInsert(statement, args),
    );
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'Update',
      statement,
      args,
      () => executor.runUpdate(statement, args),
    );
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'Delete',
      statement,
      args,
      () => executor.runDelete(statement, args),
    );
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'Select',
      statement,
      args,
      () => executor.runSelect(statement, args),
    );
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    final sw = Stopwatch()..start();
    final count = statements.statements.length;
    try {
      await executor.runBatched(statements);
      sw.stop();
      _talker.debug(
        '[Drift] Batched (${sw.elapsedMilliseconds}ms): $count statements',
      );
    } on Exception catch (e, st) {
      sw.stop();
      _talker.error(
        '[Drift] Batched Error after ${sw.elapsedMilliseconds}ms: '
        '$count statements',
        e,
        st,
      );
      rethrow;
    }
  }
}
