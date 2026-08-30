import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/storage/image_cache_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/image_cache_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

class MockImageCacheService extends Mock implements ImageCacheService {}

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTalker mockTalker;
  late MockImageCacheService mockImageCacheService;
  late MockBaseCacheManager mockCacheManager;

  setUp(() {
    mockTalker = MockTalker();
    mockImageCacheService = MockImageCacheService();
    mockCacheManager = MockBaseCacheManager();

    when(
      () => mockCacheManager.getFileStream(
        any(),
        headers: any(named: 'headers'),
        key: any(named: 'key'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);
  });

  Widget createWidget({
    String imageBaseUrl = 'https://picsum.photos',
  }) {
    return ProviderScope(
      overrides: [
        loggerProvider.overrideWithValue(mockTalker),
        imageCacheServiceProvider.overrideWithValue(mockImageCacheService),
        imageCacheManagerProvider.overrideWithValue(mockCacheManager),
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'https://api.example.com',
            imageBaseUrl: imageBaseUrl,
            aiModel: 'test-model',
            connectTimeout: 5,
            receiveTimeout: 5,
            sendTimeout: 5,
            useFirebaseAuth: false,
            useAgentPlatform: true,
          ),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ja'),
        home: ImageCacheDemoScreen(),
      ),
    );
  }

  group('ImageCacheDemoScreen Tests', () {
    testWidgets('初期表示で各セクションとボタンが表示されること', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      check(find.text('画像キャッシュデモ').evaluate()).isNotEmpty();
      check(
        find.byKey(const Key('clear_image_cache_button')).evaluate(),
      ).isNotEmpty();
      check(find.text('標準（四角形）').evaluate()).isNotEmpty();

      await tester.dragUntilVisible(
        find.text('角丸（Rounded）'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      check(find.text('角丸（Rounded）').evaluate()).isNotEmpty();

      await tester.dragUntilVisible(
        find.text('円形アバター（Circle）'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      check(find.text('円形アバター（Circle）').evaluate()).isNotEmpty();

      await tester.dragUntilVisible(
        find.text('存在しないURL（404エラー）'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      check(find.text('存在しないURL（404エラー）').evaluate()).isNotEmpty();

      await tester.dragUntilVisible(
        find.text('未設定（null / 空文字）'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      check(find.text('未設定（null / 空文字）').evaluate()).isNotEmpty();
    });

    testWidgets('キャッシュクリアボタンをタップすると clearCache が呼ばれスナックバーが表示されること', (
      tester,
    ) async {
      when(() => mockImageCacheService.clearCache()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('clear_image_cache_button'));
      await tester.tap(button);
      await tester.pumpAndSettle();

      verify(() => mockImageCacheService.clearCache()).called(1);
      check(find.text('画像キャッシュをクリアしました').evaluate()).isNotEmpty();
    });

    testWidgets('キャッシュクリア失敗時にエラーログが出力されエラースナックバーが表示されること', (
      tester,
    ) async {
      when(
        () => mockImageCacheService.clearCache(),
      ).thenThrow(Exception('Disk IO error'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('clear_image_cache_button'));
      await tester.tap(button);
      await tester.pumpAndSettle();

      verify(() => mockImageCacheService.clearCache()).called(1);
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear image cache',
        ),
      ).called(1);
      check(
        find.text('キャッシュのクリアに失敗しました: Exception: Disk IO error').evaluate(),
      ).isNotEmpty();
    });

    testWidgets('imageBaseUrl が空文字（未設定環境）の場合でも例外なく正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(imageBaseUrl: ''));
      await tester.pumpAndSettle();

      check(find.text('画像キャッシュデモ').evaluate()).isNotEmpty();
    });
  });
}
