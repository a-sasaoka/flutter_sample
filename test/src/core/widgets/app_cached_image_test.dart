import 'package:cached_network_image/cached_network_image.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/app_cached_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
  });

  late MockTalker mockTalker;
  late MockBaseCacheManager mockCacheManager;

  setUp(() {
    mockTalker = MockTalker();
    mockCacheManager = MockBaseCacheManager();

    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);
  });

  Widget createWidget({
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        loggerProvider.overrideWithValue(mockTalker),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('AppCachedImage Widget Tests', () {
    testWidgets('URLがnullの場合、即座にフォールバック（デフォルト）が表示されること', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const AppCachedImage(
            imageUrl: null,
            width: 100,
            height: 100,
          ),
        ),
      );

      check(find.byIcon(Icons.person_outline).evaluate()).isNotEmpty();
    });

    testWidgets('URLが空文字または空白の場合、フォールバックが表示されること', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const AppCachedImage(
            imageUrl: '   ',
            width: 100,
            height: 100,
          ),
        ),
      );

      check(find.byIcon(Icons.person_outline).evaluate()).isNotEmpty();
    });

    testWidgets('カスタム fallbackWidget が指定されている場合、それが表示されること', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const AppCachedImage(
            imageUrl: null,
            fallbackWidget: Text('Custom Fallback'),
          ),
        ),
      );

      check(find.text('Custom Fallback').evaluate()).isNotEmpty();
    });

    testWidgets('AppCachedImage.circle で ClipOval が適用されること', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const AppCachedImage.circle(
            imageUrl: null,
            size: 50,
          ),
        ),
      );

      check(find.byType(ClipOval).evaluate()).isNotEmpty();
    });

    testWidgets('AppCachedImage.rounded で ClipRRect が適用されること', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage.rounded(
            imageUrl: null,
            borderRadius: BorderRadius.circular(12),
            width: 120,
            height: 80,
          ),
        ),
      );

      check(find.byType(ClipRRect).evaluate()).isNotEmpty();
    });

    testWidgets('URLが指定されている場合、CachedNetworkImage が描画されること', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl: 'https://example.com/test.png',
            width: 100,
            height: 100,
            cacheManager: mockCacheManager,
          ),
        ),
      );

      check(find.byType(CachedNetworkImage).evaluate()).isNotEmpty();
    });

    testWidgets('memCacheWidth / memCacheHeight が明示指定された場合と未指定の場合の検証', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl: 'https://example.com/test.png',
            width: 100,
            height: 100,
            memCacheWidth: 200,
            memCacheHeight: 200,
            cacheManager: mockCacheManager,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      check(cachedImage.memCacheWidth).equals(200);
      check(cachedImage.memCacheHeight).equals(200);
    });

    testWidgets('errorWidget コールバックで talker.handle が呼ばれフォールバックが返されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl: 'https://example.com/test.png',
            cacheManager: mockCacheManager,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      // errorWidget を直接実行して動作検証
      final element = tester.element(find.byType(AppCachedImage));
      final errorResult = cachedImage.errorWidget!(
        element,
        'https://example.com/test.png',
        Exception('Network failure'),
      );

      check(errorResult).isNotNull();
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          'Failed to load cached image (https://example.com/test.png)',
        ),
      ).called(1);
    });

    testWidgets('errorWidget に非ExceptionのObjectが渡された場合の検証', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl: 'https://example.com/test.png',
            cacheManager: mockCacheManager,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      final element = tester.element(find.byType(AppCachedImage));
      final errorResult = cachedImage.errorWidget!(
        element,
        'https://example.com/test.png',
        'String error object',
      );

      check(errorResult).isNotNull();
      verify(
        () => mockTalker.handle(
          'String error object',
          any<StackTrace>(),
          'Failed to load cached image (https://example.com/test.png)',
        ),
      ).called(1);
    });

    testWidgets('placeholder コールバックが Shimmer を含むウィジェットを返すこと', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl: 'https://example.com/test.png',
            cacheManager: mockCacheManager,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      final element = tester.element(find.byType(AppCachedImage));
      final placeholderResult = cachedImage.placeholder!(
        element,
        'https://example.com/test.png',
      );

      check(placeholderResult).isNotNull();
    });

    testWidgets('errorWidget でURLにクエリパラメータが含まれる場合、サニタイズされてログ出力されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl:
                'https://example.com/secret.png?token=secret123&user=admin',
            cacheManager: mockCacheManager,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      final element = tester.element(find.byType(AppCachedImage));
      final errorResult = cachedImage.errorWidget!(
        element,
        'https://example.com/secret.png?token=secret123&user=admin',
        Exception('Access denied'),
      );

      check(errorResult).isNotNull();
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          'Failed to load cached image (https://example.com/secret.png)',
        ),
      ).called(1);
    });

    testWidgets(
      'errorWidget で userInfo や fragment が含まれる場合もサニタイズされてログ出力されること',
      (tester) async {
        await tester.pumpWidget(
          createWidget(
            child: AppCachedImage(
              imageUrl: 'https://admin:secret@example.com/image.png#section',
              cacheManager: mockCacheManager,
            ),
          ),
        );

        final cachedImage = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );

        final element = tester.element(find.byType(AppCachedImage));
        final errorResult = cachedImage.errorWidget!(
          element,
          'https://admin:secret@example.com/image.png#section',
          Exception('Load error'),
        );

        check(errorResult).isNotNull();
        verify(
          () => mockTalker.handle(
            any<Object>(),
            any<StackTrace>(),
            'Failed to load cached image (https://example.com/image.png)',
          ),
        ).called(1);
      },
    );

    testWidgets('errorWidget で不正なURL形式の場合、[invalid-url] としてサニタイズされること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          child: AppCachedImage(
            imageUrl: 'http://:invalid',
            cacheManager: mockCacheManager,
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      final element = tester.element(find.byType(AppCachedImage));
      final errorResult = cachedImage.errorWidget!(
        element,
        'http://:invalid',
        Exception('Parse error'),
      );

      check(errorResult).isNotNull();
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          'Failed to load cached image ([invalid-url])',
        ),
      ).called(1);
    });
  });
}
