import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
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
  group('ImageCacheDemoScreen Golden Tests', () {
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
      when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});

      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            return '.';
          });

      when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
      when(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          any<dynamic>(),
        ),
      ).thenReturn(null);
    });

    tearDown(() {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Widget buildScreenForGolden({required ThemeMode themeMode}) {
      final isDark = themeMode == ThemeMode.dark;

      return ProviderScope(
        overrides: [
          loggerProvider.overrideWithValue(mockTalker),
          imageCacheServiceProvider.overrideWithValue(mockImageCacheService),
          imageCacheManagerProvider.overrideWithValue(mockCacheManager),
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://api.example.com',
              imageBaseUrl: 'https://picsum.photos',
              aiModel: 'test-model',
              connectTimeout: 5,
              receiveTimeout: 5,
              sendTimeout: 5,
              useFirebaseAuth: false,
              useAgentPlatform: true,
            ),
          ),
        ],
        child: MaterialApp(
          theme: isDark
              ? AppTheme.dark().copyWith(
                  textTheme: AppTheme.dark().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                )
              : AppTheme.light().copyWith(
                  textTheme: AppTheme.light().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                ),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const ImageCacheDemoScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'ImageCacheDemoScreen の描画',
      fileName: 'image_cache_demo_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreenForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreenForGolden(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  });
}
