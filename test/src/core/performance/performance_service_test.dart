import 'package:checks/checks.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_sample/src/core/performance/firebase_performance_provider.dart';
import 'package:flutter_sample/src/core/performance/performance_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebasePerformance extends Mock implements FirebasePerformance {}

class MockTrace extends Mock implements Trace {}

class MockTalker extends Mock implements Talker {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
  });

  late MockFirebasePerformance mockPerformance;
  late MockTrace mockTrace;
  late MockTalker mockTalker;
  late PerformanceService service;

  setUp(() {
    mockPerformance = MockFirebasePerformance();
    mockTrace = MockTrace();
    mockTalker = MockTalker();

    when(() => mockPerformance.newTrace(any())).thenReturn(mockTrace);
    when(() => mockTrace.start()).thenAnswer((_) async {});
    when(() => mockTrace.stop()).thenAnswer((_) async {});
    when(() => mockTrace.putAttribute(any(), any())).thenReturn(null);
    when(() => mockTrace.setMetric(any(), any())).thenReturn(null);
    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);

    service = PerformanceService(
      performance: mockPerformance,
      talker: mockTalker,
    );
  });

  group('PerformanceService Tests', () {
    test('traceExecution 正常系: アクションが実行され、属性・メトリクス設定と開始・終了が行われること', () async {
      final result = await service.traceExecution<String>(
        traceName: 'custom_trace',
        action: () async => 'success_result',
        attributes: {'user_type': 'premium'},
        metrics: {'items_count': 5},
      );

      check(result).equals('success_result');
      verify(() => mockPerformance.newTrace('custom_trace')).called(1);
      verify(() => mockTrace.putAttribute('user_type', 'premium')).called(1);
      verify(() => mockTrace.setMetric('items_count', 5)).called(1);
      verify(() => mockTrace.start()).called(1);
      verify(() => mockTrace.stop()).called(1);
      verify(
        () => mockTalker.debug('⚡️ Performance trace finished: custom_trace'),
      ).called(1);
    });

    test(
      'traceExecution 正常系: attributes / metrics が null でも正常に開始・終了すること',
      () async {
        final result = await service.traceExecution<int>(
          traceName: 'simple_trace',
          action: () async => 42,
        );

        check(result).equals(42);
        verify(() => mockPerformance.newTrace('simple_trace')).called(1);
        verify(() => mockTrace.start()).called(1);
        verify(() => mockTrace.stop()).called(1);
      },
    );

    test(
      'traceExecution 正常系: performance が null の場合はカスタムトレースを行わずに action を実行すること',
      () async {
        final nullPerfService = PerformanceService(
          performance: null,
          talker: mockTalker,
        );

        final result = await nullPerfService.traceExecution<int>(
          traceName: 'skipped_trace',
          action: () async => 100,
        );

        check(result).equals(100);
        verifyNever(() => mockPerformance.newTrace(any()));
      },
    );

    test(
      'traceExecution 異常系: action 内で例外が発生した場合でも trace.stop() が呼ばれ例外が再送されること',
      () async {
        final exception = Exception('Action failed');

        await check(
          service.traceExecution<void>(
            traceName: 'failing_trace',
            action: () async => throw exception,
          ),
        ).throws<Exception>();

        verify(() => mockTrace.start()).called(1);
        verify(() => mockTrace.stop()).called(1);
      },
    );

    test(
      'traceExecution 異常系: '
      'trace.start() 時に例外が発生しても action は実行され、stop() は呼ばれないこと',
      () async {
        final startException = Exception('Failed to start trace');
        when(() => mockTrace.start()).thenThrow(startException);

        final result = await service.traceExecution<String>(
          traceName: 'start_failing_trace',
          action: () async => 'action_completed',
        );

        check(result).equals('action_completed');
        verify(
          () => mockTalker.handle(
            startException,
            any<StackTrace?>(),
            'Failed to start performance trace: start_failing_trace',
          ),
        ).called(1);
        verifyNever(() => mockTrace.stop());
      },
    );

    test(
      'traceExecution 異常系: trace.stop() 時に例外が発生した場合でも talker.handle が呼ばれること',
      () async {
        final stopException = Exception('Failed to stop trace');
        when(() => mockTrace.stop()).thenThrow(stopException);

        final result = await service.traceExecution<String>(
          traceName: 'stop_failing_trace',
          action: () async => 'result',
        );

        check(result).equals('result');
        verify(
          () => mockTalker.handle(
            stopException,
            any<StackTrace?>(),
            'Failed to stop performance trace: stop_failing_trace',
          ),
        ).called(1);
      },
    );
  });

  group('performanceServiceProvider Tests', () {
    test('performanceServiceProvider が PerformanceService インスタンスを提供すること', () {
      final container = ProviderContainer(
        overrides: [
          firebasePerformanceProvider.overrideWithValue(mockPerformance),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final performanceService = container.read(performanceServiceProvider);
      check(performanceService).isA<PerformanceService>();
      check(performanceService.performance).equals(mockPerformance);
      check(performanceService.talker).equals(mockTalker);
    });
  });
}
