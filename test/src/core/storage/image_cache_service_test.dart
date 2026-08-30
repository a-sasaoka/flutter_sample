import 'package:checks/checks.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sample/src/core/storage/image_cache_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

class MockTalker extends Mock implements Talker {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
  });

  late MockBaseCacheManager mockCacheManager;
  late MockTalker mockTalker;
  late ImageCacheService service;

  setUp(() {
    mockCacheManager = MockBaseCacheManager();
    mockTalker = MockTalker();

    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);

    service = ImageCacheService(
      talker: mockTalker,
      cacheManager: mockCacheManager,
    );
  });

  group('ImageCacheService', () {
    test('clearCache が正常にメモリとディスクのキャッシュをクリアすること', () async {
      when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});

      await check(service.clearCache()).completes();

      verify(() => mockCacheManager.emptyCache()).called(1);
      verify(
        () => mockTalker.debug('🖼️ Image cache cleared successfully.'),
      ).called(1);
    });

    test('clearCache で例外が発生した場合、talker.handle が呼ばれて例外が再スローされること', () async {
      final exception = Exception('Disk error');
      when(() => mockCacheManager.emptyCache()).thenThrow(exception);

      await check(service.clearCache()).throws<Exception>();

      verify(
        () => mockTalker.handle(
          exception,
          any<StackTrace>(),
          'Failed to clear image cache',
        ),
      ).called(1);
    });
  });

  group('imageCacheServiceProvider', () {
    test('ImageCacheService のインスタンスを提供すること', () {
      final container = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final instance = container.read(imageCacheServiceProvider);
      check(instance).isA<ImageCacheService>();
      check(instance.talker).equals(mockTalker);
    });
  });
}
