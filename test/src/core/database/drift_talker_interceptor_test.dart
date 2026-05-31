import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:flutter_sample/src/core/database/drift_talker_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

class MockQueryExecutor extends Mock implements QueryExecutor {}

class FakeBatchedStatements extends Fake implements BatchedStatements {
  @override
  List<String> get statements => ['INSERT INTO test VALUES (?)'];
}

void main() {
  group('DriftTalkerInterceptor', () {
    late MockTalker mockTalker;
    late MockQueryExecutor mockExecutor;
    late DriftTalkerInterceptor interceptor;

    setUp(() {
      mockTalker = MockTalker();
      mockExecutor = MockQueryExecutor();
      interceptor = DriftTalkerInterceptor(mockTalker);
    });

    test('runCustom がログを出力し、executor を呼び出すこと', () async {
      const sql = 'PRAGMA user_version';
      final args = <Object?>[];

      when(() => mockExecutor.runCustom(sql, args)).thenAnswer((_) async {});

      await interceptor.runCustom(mockExecutor, sql, args);

      verify(
        () => mockTalker.debug(any<String>(that: contains('[Drift] Custom'))),
      ).called(1);
      verify(() => mockExecutor.runCustom(sql, args)).called(1);
    });

    test('runInsert がログを出力し、executor を呼び出すこと', () async {
      const sql = 'INSERT INTO table (col) VALUES (?)';
      final args = ['val'];

      when(() => mockExecutor.runInsert(sql, args)).thenAnswer((_) async => 1);

      final result = await interceptor.runInsert(mockExecutor, sql, args);

      check(result).equals(1);
      verify(
        () => mockTalker.debug(any<String>(that: contains('[Drift] Insert'))),
      ).called(1);
      verify(() => mockExecutor.runInsert(sql, args)).called(1);
    });

    test('runUpdate がログを出力し、executor を呼び出すこと', () async {
      const sql = 'UPDATE table SET col = ?';
      final args = ['val'];

      when(() => mockExecutor.runUpdate(sql, args)).thenAnswer((_) async => 1);

      final result = await interceptor.runUpdate(mockExecutor, sql, args);

      check(result).equals(1);
      verify(
        () => mockTalker.debug(any<String>(that: contains('[Drift] Update'))),
      ).called(1);
      verify(() => mockExecutor.runUpdate(sql, args)).called(1);
    });

    test('runDelete がログを出力し、executor を呼び出すこと', () async {
      const sql = 'DELETE FROM table';
      final args = <Object?>[];

      when(() => mockExecutor.runDelete(sql, args)).thenAnswer((_) async => 1);

      final result = await interceptor.runDelete(mockExecutor, sql, args);

      check(result).equals(1);
      verify(
        () => mockTalker.debug(any<String>(that: contains('[Drift] Delete'))),
      ).called(1);
      verify(() => mockExecutor.runDelete(sql, args)).called(1);
    });

    test('runSelect がログを出力し、executor を呼び出すこと', () async {
      const sql = 'SELECT * FROM table';
      final args = <Object?>[];
      final expectedResult = [
        {'id': 1},
      ];

      when(
        () => mockExecutor.runSelect(sql, args),
      ).thenAnswer((_) async => expectedResult);

      final result = await interceptor.runSelect(mockExecutor, sql, args);

      check(result).equals(expectedResult);
      verify(
        () => mockTalker.debug(any<String>(that: contains('[Drift] Select'))),
      ).called(1);
      verify(() => mockExecutor.runSelect(sql, args)).called(1);
    });

    test('runBatched がログを出力し、executor を呼び出すこと', () async {
      final statements = FakeBatchedStatements();

      when(() => mockExecutor.runBatched(statements)).thenAnswer((_) async {});

      await interceptor.runBatched(mockExecutor, statements);

      verify(
        () => mockTalker.debug(any<String>(that: contains('[Drift] Batched'))),
      ).called(1);
      verify(() => mockExecutor.runBatched(statements)).called(1);
    });

    test('エラー発生時に Talker.error が呼び出されること', () async {
      const sql = 'SELECT * FROM error_table';
      final args = <Object?>[];
      final exception = Exception('DB Error');

      when(() => mockExecutor.runSelect(sql, args)).thenThrow(exception);

      await check(
        interceptor.runSelect(mockExecutor, sql, args),
      ).throws<Exception>();

      verify(
        () => mockTalker.error(
          any<String>(that: contains('[Drift] Select Error')),
          exception,
          any(),
        ),
      ).called(1);
    });

    test('runBatched でエラーが発生した場合、Talker.error が呼び出されること', () async {
      final statements = FakeBatchedStatements();
      final exception = Exception('Batch Error');

      when(() => mockExecutor.runBatched(statements)).thenThrow(exception);

      check(
        interceptor.runBatched(mockExecutor, statements),
      ).legacyMatcher(throwsA(exception));

      verify(
        () => mockTalker.error(
          any<String>(that: contains('[Drift] Batched Error')),
          exception,
          any(),
        ),
      ).called(1);
    });
  });
}
