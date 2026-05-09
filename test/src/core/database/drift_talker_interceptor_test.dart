import 'package:drift/drift.dart';
import 'package:flutter_sample/src/core/database/drift_talker_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
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
        () =>
            mockTalker.debug(any<String>(that: contains('Drift Custom: $sql'))),
      ).called(1);
      verify(() => mockExecutor.runCustom(sql, args)).called(1);
    });

    test('runInsert がログを出力し、executor を呼び出すこと', () async {
      const sql = 'INSERT INTO table (col) VALUES (?)';
      final args = ['val'];

      when(() => mockExecutor.runInsert(sql, args)).thenAnswer((_) async => 1);

      final result = await interceptor.runInsert(mockExecutor, sql, args);

      expect(result, 1);
      verify(
        () =>
            mockTalker.debug(any<String>(that: contains('Drift Insert: $sql'))),
      ).called(1);
      verify(() => mockExecutor.runInsert(sql, args)).called(1);
    });

    test('runUpdate がログを出力し、executor を呼び出すこと', () async {
      const sql = 'UPDATE table SET col = ?';
      final args = ['val'];

      when(() => mockExecutor.runUpdate(sql, args)).thenAnswer((_) async => 1);

      final result = await interceptor.runUpdate(mockExecutor, sql, args);

      expect(result, 1);
      verify(
        () =>
            mockTalker.debug(any<String>(that: contains('Drift Update: $sql'))),
      ).called(1);
      verify(() => mockExecutor.runUpdate(sql, args)).called(1);
    });

    test('runDelete がログを出力し、executor を呼び出すこと', () async {
      const sql = 'DELETE FROM table';
      final args = <Object?>[];

      when(() => mockExecutor.runDelete(sql, args)).thenAnswer((_) async => 1);

      final result = await interceptor.runDelete(mockExecutor, sql, args);

      expect(result, 1);
      verify(
        () =>
            mockTalker.debug(any<String>(that: contains('Drift Delete: $sql'))),
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

      expect(result, expectedResult);
      verify(
        () =>
            mockTalker.debug(any<String>(that: contains('Drift Select: $sql'))),
      ).called(1);
      verify(() => mockExecutor.runSelect(sql, args)).called(1);
    });

    test('runBatched がログを出力し、executor を呼び出すこと', () async {
      final statements = FakeBatchedStatements();

      when(() => mockExecutor.runBatched(statements)).thenAnswer((_) async {});

      await interceptor.runBatched(mockExecutor, statements);

      verify(
        () => mockTalker.debug(any<String>(that: contains('Drift Batched:'))),
      ).called(1);
      verify(() => mockExecutor.runBatched(statements)).called(1);
    });
  });
}
