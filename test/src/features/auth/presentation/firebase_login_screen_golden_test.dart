import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'firebase_login_screen_test.dart';

void main() {
  group('FirebaseLoginScreen Golden Tests', () {
    late MockFirebaseAuthRepository mockAuthRepo;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockAuthRepo = MockFirebaseAuthRepository();
      mockL10n = MockAppLocalizations();

      // 各翻訳テキストのダミー設定（モック）を定義します
      when(() => mockL10n.loginTitle).thenReturn('ログイン');
      when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
      when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
      when(() => mockL10n.login).thenReturn('ログインする');
      when(() => mockL10n.signUp).thenReturn('新規登録へ');
      when(() => mockL10n.googleSignUp).thenReturn('Googleでログイン');
      when(() => mockL10n.resetPassword).thenReturn('パスワードをお忘れですか？');
      when(() => mockL10n.errorLoginFailed).thenReturn('ログインに失敗しました');
      when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
      when(() => mockL10n.close).thenReturn('閉じる');
    });

    // ゴールデンテスト用にモックされた環境で画面を組み立てる関数
    Widget buildScreenForGolden({required ThemeMode themeMode}) {
      return ProviderScope(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
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
          home: const FirebaseLoginScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'FirebaseLoginScreen の描画 (ライト/ダークモード)',
      fileName: 'firebase_login_screen',
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
