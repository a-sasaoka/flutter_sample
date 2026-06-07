import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/widgets/widgets_test_helper.dart';
import 'login_screen_test.dart';

void main() {
  group('LoginScreen Golden Tests', () {
    late MockAnalyticsService mockAnalyticsService;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
      mockL10n = MockAppLocalizations();

      // 各翻訳テキストのダミー設定（モック）を定義します
      when(() => mockL10n.loginTitle).thenReturn('ログイン');
      when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
      when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
      when(() => mockL10n.loginButton).thenReturn('ログインする');
      when(() => mockL10n.loginSuccess).thenReturn('ログイン成功！');
      when(() => mockL10n.errorDialogTitle).thenReturn('エラーが発生しました');
      when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
      when(() => mockL10n.ok).thenReturn('OK');
      when(() => mockL10n.close).thenReturn('閉じる');
    });

    // ゴールデンテスト用にモックされた環境で画面を組み立てる関数
    Widget buildScreenForGolden({required ThemeMode themeMode}) {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            () => FakeAuthStateNotifier(onLogin: (a, b) async {}),
          ),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
        child: MaterialApp(
          // 日本語フォントを適用したテーマを設定します
          theme: AppTheme.light().copyWith(
            textTheme: AppTheme.light().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
          ),
          darkTheme: AppTheme.dark().copyWith(
            textTheme: AppTheme.dark().textTheme.apply(
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
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'LoginScreen の描画 (ライト/ダークモード)',
      fileName: 'login_screen',
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
