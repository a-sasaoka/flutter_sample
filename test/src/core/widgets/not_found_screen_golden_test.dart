import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'widgets_test_helper.dart';

void main() {
  group('NotFoundScreen Golden Tests', () {
    late MockGoRouter mockGoRouter;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockGoRouter = MockGoRouter();
      mockL10n = MockAppLocalizations();

      // 各翻訳テキストのダミー設定（モック）を定義します
      when(() => mockL10n.notFoundTitle).thenReturn('Page Not Found');
      when(
        () => mockL10n.notFoundMessage,
      ).thenReturn('The page could not be found.');
      when(() => mockL10n.notFoundBackToHome).thenReturn('Back to Home');
    });

    // 404画面をテスト用に構築する関数
    Widget buildNotFoundScreenForGolden({
      required ThemeMode themeMode,
      String? unknownPath,
    }) {
      final isDark = themeMode == ThemeMode.dark;
      return ProviderScope(
        child: MaterialApp(
          // テスト環境による適用漏れを防ぐため、themeに直接ライト/ダークテーマを渡します
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
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: NotFoundScreen(unknownPath: unknownPath),
          ),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'NotFoundScreen の描画 (ライト/ダークモード/パスあり)',
      fileName: 'not_found_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode - No Path',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildNotFoundScreenForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode - No Path',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildNotFoundScreenForGolden(themeMode: ThemeMode.dark),
            ),
          ),
          GoldenTestScenario(
            name: 'Light Mode - With Path',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildNotFoundScreenForGolden(
                themeMode: ThemeMode.light,
                unknownPath: '/invalid/path/test',
              ),
            ),
          ),
        ],
      ),
    );
  });
}
