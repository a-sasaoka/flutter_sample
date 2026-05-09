import 'package:drift/drift.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// DriftのクエリをTalkerでログ出力するためのインターセプター
class DriftTalkerInterceptor extends QueryInterceptor {
  /// コンストラクタ
  DriftTalkerInterceptor(this._talker);

  final Talker _talker;

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _talker.debug('Drift Custom: $statement | Args: $args');
    return executor.runCustom(statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _talker.debug('Drift Insert: $statement | Args: $args');
    return executor.runInsert(statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _talker.debug('Drift Update: $statement | Args: $args');
    return executor.runUpdate(statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _talker.debug('Drift Delete: $statement | Args: $args');
    return executor.runDelete(statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _talker.debug('Drift Select: $statement | Args: $args');
    return executor.runSelect(statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    _talker.debug('Drift Batched: ${statements.statements.length} statements');
    return executor.runBatched(statements);
  }
}
