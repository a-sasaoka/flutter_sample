import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'firebase_reset_password_screen_test.dart';

void main() {
  group('FirebaseResetPasswordScreen Golden Tests', () {
    late MockFirebaseAuthRepository mockAuthRepo;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockAuthRepo = MockFirebaseAuthRepository();
      mockL10n = MockAppLocalizations();

      // 各翻訳テキストのダミー設定（モック）を定義します
      when(() => mockL10n.resetPassword).thenReturn('パスワード再設定');
      when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
      when(() => mockL10n.send).thenReturn('送信する');
      when(() => mockL10n.resetPasswordMailSent).thenReturn('再設定メールを送信しました');
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
          home: const FirebaseResetPasswordScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'FirebaseResetPasswordScreen の描画 (ライト/ダークモード)',
      fileName: 'firebase_reset_password_screen',
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
