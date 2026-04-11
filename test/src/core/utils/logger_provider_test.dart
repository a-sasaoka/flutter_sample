import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

// recordError の呼び出しを検証するための Callable クラスとそのモック
// ignore: one_member_abstracts
abstract class RecordErrorCallable {
  Future<void> call(dynamic error, StackTrace? stackTrace);
}

class MockRecordErrorCallable extends Mock implements RecordErrorCallable {}

// TalkerObserver に渡されるエラー情報のモック
class MockTalkerError extends Mock implements TalkerError {}

class MockTalkerException extends Mock implements TalkerException {}

void main() {
  group('loggerProvider テスト', () {
    test(
      'デフォルトのまま読み取ろうとすると ProviderException(UnimplementedError) が投げられること',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(loggerProvider),
          throwsA(
            predicate((e) => e.toString().contains('UnimplementedError')),
          ),
        );
      },
    );

    test('overrideWithValue で上書きすると、その Talker インスタンスを返すこと', () {
      final mockTalker = MockTalker();
      final container = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final logger = container.read(loggerProvider);
      expect(logger, equals(mockTalker));
    });
  });

  group('CustomTalkerObserver テスト', () {
    late MockRecordErrorCallable mockRecordError;

    setUp(() {
      mockRecordError = MockRecordErrorCallable();
      // recordError が呼ばれたら何もせずに完了するようスタブ化
      when(
        () => mockRecordError.call(any<dynamic>(), any<StackTrace?>()),
      ).thenAnswer((_) async {});
    });

    test('isProd = true の場合、onError で recordError が呼ばれること', () {
      final observer = CustomTalkerObserver(
        isProd: true,
        recordError: mockRecordError.call,
      );

      final mockTalkerError = MockTalkerError();
      final error = ArgumentError('test error');
      const stackTrace = StackTrace.empty;

      when(() => mockTalkerError.error).thenReturn(error);
      when(() => mockTalkerError.stackTrace).thenReturn(stackTrace);

      observer.onError(mockTalkerError);

      verify(() => mockRecordError.call(error, stackTrace)).called(1);
    });

    test('isProd = false の場合、onError で recordError が呼ばれないこと', () {
      final observer = CustomTalkerObserver(
        isProd: false,
        recordError: mockRecordError.call,
      );

      final mockTalkerError = MockTalkerError();
      final error = ArgumentError('test error');
      const stackTrace = StackTrace.empty;

      when(() => mockTalkerError.error).thenReturn(error);
      when(() => mockTalkerError.stackTrace).thenReturn(stackTrace);

      observer.onError(mockTalkerError);

      verifyNever(
        () => mockRecordError.call(any<dynamic>(), any<StackTrace?>()),
      );
    });

    test('isProd = true の場合、onException で recordError が呼ばれること', () {
      final observer = CustomTalkerObserver(
        isProd: true,
        recordError: mockRecordError.call,
      );

      final mockTalkerException = MockTalkerException();
      final exception = Exception('test exception');
      const stackTrace = StackTrace.empty;

      when(() => mockTalkerException.exception).thenReturn(exception);
      when(() => mockTalkerException.stackTrace).thenReturn(stackTrace);

      observer.onException(mockTalkerException);

      verify(() => mockRecordError.call(exception, stackTrace)).called(1);
    });

    test('isProd = false の場合、onException で recordError が呼ばれないこと', () {
      final observer = CustomTalkerObserver(
        isProd: false,
        recordError: mockRecordError.call,
      );

      final mockTalkerException = MockTalkerException();
      final exception = Exception('test exception');
      const stackTrace = StackTrace.empty;

      when(() => mockTalkerException.exception).thenReturn(exception);
      when(() => mockTalkerException.stackTrace).thenReturn(stackTrace);

      observer.onException(mockTalkerException);

      verifyNever(
        () => mockRecordError.call(any<dynamic>(), any<StackTrace?>()),
      );
    });
  });
}
