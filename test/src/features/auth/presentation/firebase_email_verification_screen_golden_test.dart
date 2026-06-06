import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'firebase_email_verification_screen_test.dart';

void main() {
  group('FirebaseEmailVerificationScreen Golden Tests', () {
    late MockFirebaseAuthRepository mockAuthRepo;
    late MockUser mockUser;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockAuthRepo = MockFirebaseAuthRepository();
      mockUser = MockUser();
      mockL10n = MockAppLocalizations();

      // 各翻訳テキストのダミー設定（モック）を定義します
      when(() => mockL10n.emailVerificationTitle).thenReturn('メール認証');
      when(
        () => mockL10n.emailVerificationDescription,
      ).thenReturn('確認メールを送信しました。');
      when(() => mockL10n.resendVerificationMail).thenReturn('再送信する');
      when(() => mockL10n.emailVerificationWaiting).thenReturn('認証待ちです...');
      when(() => mockL10n.checkVerificationStatus).thenReturn('認証を完了したか確認する');
      when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました。');
      when(() => mockL10n.close).thenReturn('閉じる');
      when(() => mockL10n.login).thenReturn('ログイン');
      when(() => mockL10n.logout).thenReturn('ログアウトして戻る');
      when(
        () => mockL10n.resendVerificationMailSuccess,
      ).thenReturn('確認メールを再送信しました');

      when(() => mockUser.emailVerified).thenReturn(false);
      when(() => mockAuthRepo.sendEmailVerification()).thenAnswer((_) async {});
      when(() => mockAuthRepo.reloadCurrentUser()).thenAnswer((_) async {});
    });

    // ゴールデンテスト用にモックされた環境で画面を組み立てる関数
    Widget buildScreenForGolden({required ThemeMode themeMode}) {
      return ProviderScope(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
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
          home: const FirebaseEmailVerificationScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'FirebaseEmailVerificationScreen の描画 (ライト/ダークモード)',
      fileName: 'firebase_email_verification_screen',
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
