import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'home_screen_test.dart';

void main() {
  group('HomeScreen Golden Tests', () {
    late MockAppLocalizations mockL10n;
    late MockTalker mockTalker;

    setUp(() {
      mockL10n = MockAppLocalizations();
      mockTalker = MockTalker();

      when(() => mockL10n.homeTitle).thenReturn('ホーム');
      when(() => mockL10n.homeDescription).thenReturn('ホーム画面の説明');
      when(() => mockL10n.homeCurrentEnv).thenReturn('現在の環境');
      when(() => mockL10n.homeToSettings).thenReturn('設定');
      when(() => mockL10n.homeToUserList).thenReturn('ユーザー一覧');
      when(() => mockL10n.homeToResetPassword).thenReturn('パスワードリセット');
      when(() => mockL10n.homeToChat).thenReturn('AIチャット');
      when(() => mockL10n.homeToMemos).thenReturn('メモ帳');
      when(() => mockL10n.homeToGraph).thenReturn('グラフ');
      when(() => mockL10n.homeToNotFound).thenReturn('404テスト');
      when(() => mockL10n.homeGetAppInfo).thenReturn('アプリ情報取得');
      when(() => mockL10n.homeAppName).thenReturn('アプリ名');
      when(() => mockL10n.homeBundleId).thenReturn('Bundle ID');
      when(() => mockL10n.homeCrashTest).thenReturn('クラッシュテスト');
      when(() => mockL10n.homeAnalyticsTest).thenReturn('分析テスト');
      when(() => mockL10n.developerLogTitle).thenReturn('開発者ログ');
      when(() => mockL10n.versionUpTitle).thenReturn('アップデート');
      when(() => mockL10n.versionUpMessageOptional).thenReturn('オプション');
      when(() => mockL10n.versionUpMessageMandatory).thenReturn('必須');
      when(() => mockL10n.versionUpUpdate).thenReturn('更新');
      when(() => mockL10n.versionUpCancel).thenReturn('後で');
      when(() => mockL10n.close).thenReturn('閉じる');
      when(() => mockL10n.ok).thenReturn('OK');
      when(() => mockL10n.devStorageTitle).thenReturn('ストレージ確認・編集');
    });

    Widget buildHomeForGolden({required ThemeMode themeMode}) {
      final dummyPackageInfo = PackageInfo(
        appName: 'テストアプリ',
        packageName: 'com.example.testapp',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'test_sig',
      );

      return ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.local),
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://test.example.com',
              aiModel: 'test-model',
              connectTimeout: 10,
              receiveTimeout: 15,
              sendTimeout: 10,
              useFirebaseAuth: true,
            ),
          ),
          updateRequestControllerProvider.overrideWith(
            FakeUpdateRequestController.new,
          ),
          cancelControllerProvider.overrideWith(
            () => FakeCancelController(initialValue: false),
          ),
          loggerProvider.overrideWithValue(mockTalker),
          packageInfoProvider.overrideWithValue(dummyPackageInfo),
        ],
        child: MaterialApp(
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
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'HomeScreen の描画 (ライト/ダークモード)',
      fileName: 'home_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildHomeForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildHomeForGolden(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  });
}
