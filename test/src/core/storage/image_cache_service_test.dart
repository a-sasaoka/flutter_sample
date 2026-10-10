import 'package:checks/checks.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sample/src/core/storage/image_cache_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

class MockTalker extends Mock implements Talker {}

class TestUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'user-1';
  String? get userId => state;
  set userId(String? id) => state = id;
}

final testUserIdProvider = NotifierProvider<TestUserIdNotifier, String?>(
  TestUserIdNotifier.new,
);

class TestAuthNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  bool get isAuthenticated => state;
  set isAuthenticated(bool value) => state = value;
}

final testAuthNotifierProvider = NotifierProvider<TestAuthNotifier, bool>(
  TestAuthNotifier.new,
);

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
      () =>
          mockTalker.handle(any<Object>(), any<StackTrace?>(), any<dynamic>()),
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
          imageCacheManagerProvider.overrideWithValue(mockCacheManager),
        ],
      );
      addTearDown(container.dispose);

      final instance = container.read(imageCacheServiceProvider);
      check(instance).isA<ImageCacheService>();
      check(instance.talker).equals(mockTalker);
      check(instance.cacheManager).equals(mockCacheManager);
    });
  });

  group('imageCacheServiceProvider 認証連動テスト', () {
    late ProviderContainer authContainer;

    setUp(() {
      authContainer = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(mockTalker),
          imageCacheManagerProvider.overrideWithValue(mockCacheManager),
          currentUserIdProvider.overrideWith(
            (ref) => ref.watch(testUserIdProvider),
          ),
          isAuthenticatedProvider.overrideWith(
            (ref) => ref.watch(testAuthNotifierProvider),
          ),
        ],
      );
    });

    tearDown(() {
      authContainer.dispose();
    });

    test(
      'currentUserIdProvider の変化（アカウント切り替え）時に clearCache が自動呼び出しされること',
      () async {
        when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});

        // サービスを購読して初期化
        authContainer.listen(imageCacheServiceProvider, (_, _) {});

        // ユーザーIDを変更（アカウント切り替え）
        authContainer.read(testUserIdProvider.notifier).userId = 'user-2';
        authContainer.read(currentUserIdProvider);

        await pumpEventQueue();

        verify(() => mockCacheManager.emptyCache()).called(1);
      },
    );

    test(
      'isAuthenticatedProvider の変化（ログアウト）時に clearCache が自動呼び出しされること',
      () async {
        when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});

        // サービスを購読して初期化
        authContainer.listen(imageCacheServiceProvider, (_, _) {});

        // ログアウト
        authContainer.read(testAuthNotifierProvider.notifier).isAuthenticated =
            false;
        authContainer.read(isAuthenticatedProvider);

        await pumpEventQueue();

        verify(() => mockCacheManager.emptyCache()).called(1);
      },
    );

    test('認証連動の clearCache 実行時に例外が発生してもクラッシュしないこと', () async {
      final exception = Exception('Disk error');
      when(() => mockCacheManager.emptyCache()).thenThrow(exception);

      // サービスを購読して初期化
      authContainer.listen(imageCacheServiceProvider, (_, _) {});

      // ログアウト
      authContainer.read(testAuthNotifierProvider.notifier).isAuthenticated =
          false;
      authContainer.read(isAuthenticatedProvider);

      await pumpEventQueue();

      verify(() => mockCacheManager.emptyCache()).called(1);
      verify(
        () => mockTalker.handle(
          exception,
          any<StackTrace>(),
          'Failed to clear image cache',
        ),
      ).called(1);
    });
  });
}
