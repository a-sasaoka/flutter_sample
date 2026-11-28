import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/profile/data/storage_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モックとFakeクラスの定義 ---

class MockAuthService extends Mock implements AuthService {}

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockStorageService extends Mock implements StorageService {}

class MockMemoRepository extends Mock implements MemoRepository {}

class MockQrScanHistoriesDao extends Mock implements QrScanHistoriesDao {}

class MockCacheManager extends Mock implements CacheManager {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class _FakeDeletionAuthStateNotifier extends AuthStateNotifier {
  @override
  Future<bool> build() async => true;
}

class _StubHttpClientAdapter implements HttpClientAdapter {
  _StubHttpClientAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _onFetch(options);

  @override
  void close({bool force = false}) {}
}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class FakeThemeSchemeNotifier extends ThemeSchemeNotifier {
  FakeThemeSchemeNotifier([
    this._initialScheme = ThemeSchemeNotifier.defaultScheme,
  ]);
  final FlexScheme _initialScheme;

  FlexScheme? calledSetScheme;

  @override
  Future<FlexScheme> build() async => _initialScheme;

  @override
  Future<void> setScheme(FlexScheme scheme) async {
    calledSetScheme = scheme;
  }
}

class LoadingThemeSchemeNotifier extends ThemeSchemeNotifier {
  @override
  Future<FlexScheme> build() => Completer<FlexScheme>().future;
}

class FakeTextScaleNotifier extends TextScaleNotifier {
  FakeTextScaleNotifier([this._initialScale = TextScaleNotifier.defaultScale]);
  final AppTextScale _initialScale;

  AppTextScale? calledSetScale;

  @override
  Future<AppTextScale> build() async => _initialScale;

  @override
  Future<void> setScale(AppTextScale scale) async {
    calledSetScale = scale;
  }
}

class LoadingTextScaleNotifier extends TextScaleNotifier {
  @override
  Future<AppTextScale> build() => Completer<AppTextScale>().future;
}

class FakeThemeModeNotifier extends ThemeModeNotifier {
  FakeThemeModeNotifier([this._initialMode = ThemeMode.system]);
  final ThemeMode _initialMode;

  ThemeMode? calledSetMode;
  bool calledToggle = false;

  @override
  Future<ThemeMode> build() async => _initialMode;

  @override
  Future<void> set(ThemeMode mode) async {
    calledSetMode = mode;
  }

  @override
  Future<void> toggleLightDark() async {
    calledToggle = true;
  }
}

class LoadingThemeModeNotifier extends ThemeModeNotifier {
  @override
  Future<ThemeMode> build() => Completer<ThemeMode>().future;
}

class FakeLocaleNotifier extends LocaleNotifier {
  FakeLocaleNotifier([this._initialLocale]);
  final Locale? _initialLocale;

  String? calledSetLocale;

  @override
  Future<Locale?> build() async => _initialLocale;

  @override
  Future<void> setLocale(String? locale) async {
    calledSetLocale = locale;
  }
}

class LoadingLocaleNotifier extends LocaleNotifier {
  @override
  Future<Locale?> build() => Completer<Locale?>().future;
}

class MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

void main() {
  late MockAuthService mockAuthService;
  late MockAppLocalizations mockL10n;
  late FakeThemeSchemeNotifier fakeThemeSchemeNotifier;
  late FakeTextScaleNotifier fakeTextScaleNotifier;
  late FakeThemeModeNotifier fakeThemeModeNotifier;
  late FakeLocaleNotifier fakeLocaleNotifier;

  setUp(() {
    mockAuthService = MockAuthService();
    mockL10n = MockAppLocalizations();

    fakeThemeSchemeNotifier = FakeThemeSchemeNotifier();
    fakeTextScaleNotifier = FakeTextScaleNotifier();
    fakeThemeModeNotifier = FakeThemeModeNotifier();
    fakeLocaleNotifier = FakeLocaleNotifier();

    // 翻訳モックの設定
    when(() => mockL10n.settingsTitle).thenReturn('設定');
    when(() => mockL10n.profileTitle).thenReturn('プロフィール');
    when(() => mockL10n.settingsThemeSection).thenReturn('テーマ設定');
    when(() => mockL10n.settingsThemeSystem).thenReturn('システム');
    when(() => mockL10n.settingsThemeLight).thenReturn('ライト');
    when(() => mockL10n.settingsThemeDark).thenReturn('ダーク');
    when(() => mockL10n.settingsThemeToggle).thenReturn('ダークモードにする');
    when(() => mockL10n.settingsColorSection).thenReturn('テーマカラー設定');
    when(() => mockL10n.settingsColorIndigo).thenReturn('インディゴ');
    when(() => mockL10n.settingsColorTeal).thenReturn('ティール');
    when(() => mockL10n.settingsColorOrange).thenReturn('オレンジ');
    when(() => mockL10n.settingsColorPink).thenReturn('ピンク');
    when(() => mockL10n.settingsTextScaleSection).thenReturn('文字サイズ設定');
    when(() => mockL10n.settingsTextScaleSmall).thenReturn('小');
    when(() => mockL10n.settingsTextScaleNormal).thenReturn('標準');
    when(() => mockL10n.settingsTextScaleLarge).thenReturn('大');
    when(() => mockL10n.settingsTextScalePreview).thenReturn('文字サイズのプレビュー表示です');
    when(() => mockL10n.settingsLocaleSection).thenReturn('言語設定');
    when(() => mockL10n.settingsLocaleSystem).thenReturn('システム依存');
    when(() => mockL10n.settingsLocaleJa).thenReturn('日本語');
    when(() => mockL10n.settingsLocaleEn).thenReturn('英語');
    when(() => mockL10n.hello).thenReturn('こんにちは！');
    when(() => mockL10n.logout).thenReturn('ログアウト');
    when(() => mockL10n.close).thenReturn('閉じる');
    when(() => mockL10n.settingsLegalSection).thenReturn('📜 法的情報');
    when(() => mockL10n.termsOfServiceTitle).thenReturn('利用規約');
    when(() => mockL10n.privacyPolicyTitle).thenReturn('プライバシーポリシー');

    // エラーハンドラー経由で表示される翻訳キー
    when(() => mockL10n.errorUnknown).thenReturn('不明なエラー');
    when(() => mockL10n.errorOccurred).thenReturn('エラーが発生しました');
    when(() => mockL10n.errorServer).thenReturn('サーバーエラー');
    when(() => mockL10n.errorUnauthorized).thenReturn('権限エラー');
    when(() => mockL10n.errorRequiresRecentLogin).thenReturn('再認証が必要です');
    when(() => mockL10n.errorWrongPassword).thenReturn('パスワードが正しくありません');
    when(() => mockL10n.errorUserMismatch).thenReturn('アカウントが一致しません');
    when(() => mockL10n.errorReauthCancelled).thenReturn('再認証がキャンセルされました');
    when(() => mockL10n.settingsPreview).thenReturn('プレビュー');

    // アカウント削除・再認証関連の翻訳キー
    when(() => mockL10n.cancel).thenReturn('キャンセル');
    when(() => mockL10n.accountDeletionButton).thenReturn('アカウントを削除（退会）');
    when(() => mockL10n.accountDeletionStep1Title).thenReturn('アカウント削除の確認');
    when(
      () => mockL10n.accountDeletionStep1Description,
    ).thenReturn('以下のデータが完全に消去されます。');
    when(() => mockL10n.accountDeletionItemAccount).thenReturn('・アカウント情報');
    when(() => mockL10n.accountDeletionItemProfile).thenReturn('・プロフィール');
    when(() => mockL10n.accountDeletionItemMemos).thenReturn('・メモ');
    when(() => mockL10n.accountDeletionItemHistory).thenReturn('・履歴');
    when(() => mockL10n.accountDeletionStep1Continue).thenReturn('退会手続きへ進む');
    when(() => mockL10n.accountDeletionStep2Title).thenReturn('最終確認');
    when(
      () => mockL10n.accountDeletionStep2Description,
    ).thenReturn('本当によろしいですか？');
    when(
      () => mockL10n.accountDeletionStep2Confirm,
    ).thenReturn('アカウントを完全に削除する');
    when(
      () => mockL10n.accountDeletionProcessing,
    ).thenReturn('アカウントとデータを削除しています...');
    when(() => mockL10n.reauthDialogTitle).thenReturn('本人確認（再認証）');
    when(() => mockL10n.reauthDialogDescription).thenReturn('再認証を行ってください。');
    when(
      () => mockL10n.reauthTargetEmailLabel(any()),
    ).thenAnswer((invocation) => '対象: ${invocation.positionalArguments[0]}');
    when(() => mockL10n.reauthPasswordTab).thenReturn('パスワード');
    when(() => mockL10n.reauthGoogleTab).thenReturn('Google');
    when(() => mockL10n.reauthPasswordSubmit).thenReturn('パスワードで確認して続行');
    when(() => mockL10n.reauthGoogleSubmit).thenReturn('Googleアカウントで再認証');
    when(() => mockL10n.reauthUnavailableProvider).thenReturn('認証手段なし');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード入力');
    when(() => mockL10n.validationEmailRequired).thenReturn('メール必須');
    when(() => mockL10n.validationEmailInvalid).thenReturn('メール不正');
    when(() => mockL10n.validationPasswordRequired).thenReturn('パスワード必須');
    when(() => mockL10n.validationNotOnlyWhitespace).thenReturn('空白のみ禁止');

    // 認証サービスメソッドのスタブ
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
  });

  Widget createTestWidget({
    bool useAuth = true,
    bool isAuthed = true,
    ThemeSchemeNotifier Function()? themeSchemeOverride,
    TextScaleNotifier Function()? textScaleOverride,
    ThemeModeNotifier Function()? themeModeOverride,
    LocaleNotifier Function()? localeOverride,
  }) {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Text('Navigated to ${state.uri}')),
    );

    return ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'https://test.example.com',
            imageBaseUrl: defaultImageBaseUrl,
            aiModel: 'test-model',
            connectTimeout: 10,
            receiveTimeout: 15,
            sendTimeout: 10,
            useFirebaseAuth: useAuth,
            useAgentPlatform: true,
          ),
        ),
        isAuthenticatedProvider.overrideWithValue(isAuthed),
        authServiceProvider.overrideWithValue(mockAuthService),
        themeSchemeProvider.overrideWith(
          themeSchemeOverride ?? () => fakeThemeSchemeNotifier,
        ),
        textScaleProvider.overrideWith(
          textScaleOverride ?? () => fakeTextScaleNotifier,
        ),
        themeModeProvider.overrideWith(
          themeModeOverride ?? () => fakeThemeModeNotifier,
        ),
        localeProvider.overrideWith(localeOverride ?? () => fakeLocaleNotifier),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [
          MockLocalizationsDelegate(mockL10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  group('SettingsScreen', () {
    void setMobileView(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('テーマ設定が読み込み中の場合でも、デフォルト値（システム）で安全にフォールバック表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(themeModeOverride: LoadingThemeModeNotifier.new),
      );
      await tester.pump();

      final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      check(segmentedButton.selected.single).equals(ThemeMode.system);
    });

    testWidgets('テーマカラー設定が読み込み中の場合でも、デフォルト値（インディゴ）で安全にフォールバック表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(themeSchemeOverride: LoadingThemeSchemeNotifier.new),
      );
      await tester.pump();

      final indigoChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'インディゴ'),
      );
      check(indigoChip.selected).isTrue();
    });

    testWidgets('文字サイズ設定が読み込み中の場合でも、デフォルト値（標準）で安全にフォールバック表示されること', (
      tester,
    ) async {
      setMobileView(tester);
      await tester.pumpWidget(
        createTestWidget(textScaleOverride: LoadingTextScaleNotifier.new),
      );
      await tester.pump();

      final segmentedButton = tester.widget<SegmentedButton<AppTextScale>>(
        find.byType(SegmentedButton<AppTextScale>),
      );
      check(segmentedButton.selected.single).equals(AppTextScale.normal);
    });

    testWidgets('言語設定が読み込み中の場合でも、デフォルト値（システム依存）で安全にフォールバック表示されること', (
      tester,
    ) async {
      setMobileView(tester);
      await tester.pumpWidget(
        createTestWidget(localeOverride: LoadingLocaleNotifier.new),
      );
      await tester.pump();

      final segmentedButton = tester.widget<SegmentedButton<String?>>(
        find.byType(SegmentedButton<String?>),
      );
      check(segmentedButton.selected.single).isNull();
    });

    group('データ取得完了後 (Data状態)', () {
      testWidgets('UIが正しくレンダリングされること', (tester) async {
        setMobileView(tester);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        check(find.text('設定')).findsOne();
        check(find.text('テーマ設定')).findsOne();
        check(find.text('ライト')).findsOne();
        check(find.text('テーマカラー設定')).findsOne();
        check(find.text('インディゴ')).findsOne();
        check(find.text('ティール')).findsOne();
        check(find.text('オレンジ')).findsOne();
        check(find.text('ピンク')).findsOne();
        check(find.text('文字サイズ設定')).findsOne();
        check(find.text('小')).findsOne();
        check(find.text('標準')).findsOne();
        check(find.text('大')).findsOne();
        check(find.text('文字サイズのプレビュー表示です')).findsOne();
        check(find.text('言語設定')).findsOne();
        check(find.text('プレビュー: こんにちは！')).findsOne();
      });

      testWidgets(
        '文字サイズのSegmentedButtonを変更した時、TextScaleNotifier.setScaleが呼ばれること',
        (tester) async {
          setMobileView(tester);
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final largeButton = find.text('大');
          await tester.dragUntilVisible(
            largeButton,
            find.byType(ListView),
            const Offset(0, -300),
          );

          // 大を選択
          await tester.tap(largeButton);
          await tester.pumpAndSettle();

          check(
            fakeTextScaleNotifier.calledSetScale,
          ).equals(AppTextScale.large);
        },
      );

      testWidgets(
        'テーマカラーのChoiceChipを変更した時、ThemeSchemeNotifier.setSchemeが呼ばれること',
        (tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          // ティールを選択
          await tester.tap(find.text('ティール'));
          await tester.pumpAndSettle();

          check(
            fakeThemeSchemeNotifier.calledSetScheme,
          ).equals(FlexScheme.tealM3);
        },
      );

      testWidgets('テーマのSegmentedButtonを変更した時、ThemeModeNotifierのsetが呼ばれること', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ダークを選択
        await tester.tap(find.text('ダーク'));
        await tester.pumpAndSettle();

        check(fakeThemeModeNotifier.calledSetMode).equals(ThemeMode.dark);
      });

      testWidgets('テーマのSwitchを切り替えた時、toggleLightDarkが呼ばれること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        check(fakeThemeModeNotifier.calledToggle).equals(true);
      });

      testWidgets('言語のSegmentedButtonを変更した時、LocaleNotifier.setLocaleが呼ばれること', (
        tester,
      ) async {
        setMobileView(tester);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final englishButton = find.text('英語');
        await tester.dragUntilVisible(
          englishButton,
          find.byType(ListView),
          const Offset(0, -300),
        );

        // 英語を選択
        await tester.tap(englishButton);
        await tester.pumpAndSettle();

        check(fakeLocaleNotifier.calledSetLocale).equals('en');
      });

      group('ログアウトボタン', () {
        testWidgets('isAuthed == false の場合、ログアウトボタンは表示されないこと', (tester) async {
          await tester.pumpWidget(createTestWidget(isAuthed: false));
          await tester.pumpAndSettle();

          check(find.byKey(const Key('logout_button'))).findsNothing();
        });

        testWidgets('isAuthed == true でログアウト成功時、signOut処理が呼ばれること', (
          tester,
        ) async {
          setMobileView(tester);

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final logoutButton = find.byKey(const Key('logout_button'));
          await tester.dragUntilVisible(
            logoutButton,
            find.byType(ListView),
            const Offset(0, -300),
          );

          await tester.tap(logoutButton);
          await tester.pumpAndSettle();

          verify(() => mockAuthService.signOut()).called(1);
        });

        testWidgets('useAuth: false（自前認証）でもログアウトボタンが表示され signOut が呼ばれること', (
          tester,
        ) async {
          setMobileView(tester);

          await tester.pumpWidget(createTestWidget(useAuth: false));
          await tester.pumpAndSettle();

          final logoutButton = find.byKey(const Key('logout_button'));
          await tester.dragUntilVisible(
            logoutButton,
            find.byType(ListView),
            const Offset(0, -300),
          );

          await tester.tap(logoutButton);
          await tester.pumpAndSettle();

          verify(() => mockAuthService.signOut()).called(1);
        });

        testWidgets('ログアウト時に例外が発生した場合、SnackBarでエラーが表示されること', (tester) async {
          setMobileView(tester);

          final exception = Exception('Logout failed!');
          when(() => mockAuthService.signOut()).thenThrow(exception);

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final logoutButton = find.byKey(const Key('logout_button'));
          await tester.dragUntilVisible(
            logoutButton,
            find.byType(ListView),
            const Offset(0, -300),
          );

          await tester.tap(logoutButton);
          await tester.pump();

          verify(() => mockAuthService.signOut()).called(1);

          check(find.textContaining('不明なエラー')).findsOne();
          check(find.textContaining('Navigated to')).findsNothing();
        });
      });

      testWidgets('プロフィール設定をタップした際、ProfileEditRouteへ遷移すること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // プロフィールをタップ
        await tester.tap(find.text('プロフィール'));
        await tester.pumpAndSettle();

        // 遷移処理が行われたことをGoRouterのerrorBuilderのダミーテキストで確認
        check(find.textContaining('Navigated to /settings/profile')).findsOne();
      });

      testWidgets('利用規約をタップした際、TermsRouteへ遷移すること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final tileFinder = find.byKey(const Key('terms_of_service_tile'));
        await tester.dragUntilVisible(
          tileFinder,
          find.byType(ListView),
          const Offset(0, -300),
        );

        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        check(find.textContaining('Navigated to /terms')).findsOne();
      });

      testWidgets('プライバシーポリシーをタップした際、PrivacyPolicyRouteへ遷移すること', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final tileFinder = find.byKey(const Key('privacy_policy_tile'));
        await tester.dragUntilVisible(
          tileFinder,
          find.byType(ListView),
          const Offset(0, -300),
        );

        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        check(find.textContaining('Navigated to /privacy')).findsOne();
      });

      group('アカウント削除', () {
        Future<void> openStep1(WidgetTester tester) async {
          final deleteButton = find.byKey(const Key('delete_account_button'));
          await tester.dragUntilVisible(
            deleteButton,
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.tap(deleteButton);
          await tester.pumpAndSettle();
        }

        Future<void> proceedToStep2(WidgetTester tester) async {
          await openStep1(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step1_continue')),
          );
          await tester.pumpAndSettle();
        }

        testWidgets('未認証時はアカウント削除ボタンが表示されないこと', (tester) async {
          setMobileView(tester);
          await tester.pumpWidget(createTestWidget(isAuthed: false));
          await tester.pumpAndSettle();

          await tester.drag(find.byType(ListView), const Offset(0, -600));
          await tester.pumpAndSettle();

          check(find.byKey(const Key('delete_account_button'))).findsNothing();
        });

        testWidgets('認証済み時はスクロール後にアカウント削除ボタンが表示されること', (tester) async {
          setMobileView(tester);
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final deleteButton = find.byKey(const Key('delete_account_button'));
          await tester.dragUntilVisible(
            deleteButton,
            find.byType(ListView),
            const Offset(0, -300),
          );

          check(deleteButton).findsOne();
          check(find.text('アカウントを削除（退会）')).findsOne();
        });

        testWidgets('Step 1 ダイアログでキャンセルした場合、Step 2 や削除処理に進まないこと', (
          tester,
        ) async {
          setMobileView(tester);
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await openStep1(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step1_cancel')),
          );
          await tester.pumpAndSettle();

          check(
            find.byKey(const Key('account_deletion_step2_confirm')),
          ).findsNothing();
          verifyNever(() => mockAuthService.checkReauthRequirement());
          verifyNever(() => mockAuthService.deleteAccount());
        });

        testWidgets('Step 2 ダイアログでキャンセルした場合、事前チェックや削除処理に進まないこと', (
          tester,
        ) async {
          setMobileView(tester);
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_cancel')),
          );
          await tester.pumpAndSettle();

          verifyNever(() => mockAuthService.checkReauthRequirement());
          verifyNever(() => mockAuthService.deleteAccount());
        });

        testWidgets('事前チェック（checkReauthRequirement）失敗時、エラーSnackBarを表示すること', (
          tester,
        ) async {
          setMobileView(tester);
          when(
            () => mockAuthService.checkReauthRequirement(),
          ).thenThrow(const AppException.server(statusCode: 500));

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pumpAndSettle();

          check(find.textContaining('サーバーエラー')).findsOne();
          verifyNever(() => mockAuthService.deleteAccount());
        });

        testWidgets('直近ログインが新鮮な場合、再認証なしで処理中ダイアログ表示後に deleteAccount が完了すること', (
          tester,
        ) async {
          setMobileView(tester);
          final deleteCompleter = Completer<void>();
          when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
            (_) async => const AccountDeletionPrecheck(
              requiresReauthentication: false,
              availableMethods: {ReauthMethod.password},
              email: 'user@example.com',
            ),
          );
          when(
            () => mockAuthService.deleteAccount(),
          ).thenAnswer((_) => deleteCompleter.future);

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pump();
          await tester.pump();

          check(
            find.byKey(const Key('account_deletion_processing_dialog')),
          ).findsOne();

          deleteCompleter.complete();
          await tester.pumpAndSettle();

          check(
            find.byKey(const Key('account_deletion_processing_dialog')),
          ).findsNothing();
          verify(() => mockAuthService.deleteAccount()).called(1);
        });

        testWidgets('事前再認証モーダルでキャンセルした場合、deleteAccount は呼ばれないこと', (
          tester,
        ) async {
          setMobileView(tester);
          when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
            (_) async => const AccountDeletionPrecheck(
              requiresReauthentication: true,
              availableMethods: {ReauthMethod.password},
              email: 'user@example.com',
            ),
          );

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pumpAndSettle();

          check(find.text('本人確認（再認証）')).findsOne();
          await tester.tap(find.byKey(const Key('reauth_cancel_button')));
          await tester.pumpAndSettle();

          verifyNever(() => mockAuthService.deleteAccount());
        });

        testWidgets('事前再認証（パスワード）成功後に deleteAccount が実行されること', (tester) async {
          setMobileView(tester);
          when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
            (_) async => const AccountDeletionPrecheck(
              requiresReauthentication: true,
              availableMethods: {ReauthMethod.password},
              email: 'user@example.com',
            ),
          );
          when(
            () => mockAuthService.reauthenticateWithPassword(
              password: 'secret-password',
              email: 'user@example.com',
            ),
          ).thenAnswer((_) async {});
          when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byKey(const Key('reauth_password_field')),
            'secret-password',
          );
          await tester.tap(
            find.byKey(const Key('reauth_password_submit_button')),
          );
          await tester.pumpAndSettle();

          verify(
            () => mockAuthService.reauthenticateWithPassword(
              password: 'secret-password',
              email: 'user@example.com',
            ),
          ).called(1);
          verify(() => mockAuthService.deleteAccount()).called(1);
        });

        testWidgets('事前再認証（Google）成功後に deleteAccount が実行されること', (tester) async {
          setMobileView(tester);
          when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
            (_) async => const AccountDeletionPrecheck(
              requiresReauthentication: true,
              availableMethods: {ReauthMethod.google},
            ),
          );
          when(
            () => mockAuthService.reauthenticateWithGoogle(),
          ).thenAnswer((_) async {});
          when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('reauth_google_submit_button')),
          );
          await tester.pumpAndSettle();

          verify(() => mockAuthService.reauthenticateWithGoogle()).called(1);
          verify(() => mockAuthService.deleteAccount()).called(1);
        });

        testWidgets(
          '事後 ReauthRequiresRecentLoginException 時に再認証モーダル経由で再試行し完了すること',
          (tester) async {
            setMobileView(tester);
            var deleteAttempt = 0;
            when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
              (_) async => const AccountDeletionPrecheck(
                requiresReauthentication: false,
                availableMethods: {ReauthMethod.password},
                email: 'user@example.com',
              ),
            );
            when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {
              deleteAttempt++;
              if (deleteAttempt == 1) {
                throw const ReauthRequiresRecentLoginException();
              }
            });
            when(
              () => mockAuthService.reauthenticateWithPassword(
                password: 'retry-password',
                email: 'user@example.com',
              ),
            ).thenAnswer((_) async {});

            await tester.pumpWidget(createTestWidget());
            await tester.pumpAndSettle();

            await proceedToStep2(tester);
            await tester.tap(
              find.byKey(const Key('account_deletion_step2_confirm')),
            );
            await tester.pumpAndSettle();

            // フォールバック再認証モーダルが表示されること
            check(find.text('本人確認（再認証）')).findsOne();
            await tester.enterText(
              find.byKey(const Key('reauth_password_field')),
              'retry-password',
            );
            await tester.tap(
              find.byKey(const Key('reauth_password_submit_button')),
            );
            await tester.pumpAndSettle();

            check(deleteAttempt).equals(2);
            verify(() => mockAuthService.deleteAccount()).called(2);
          },
        );

        testWidgets(
          '再試行後も ReauthRequiresRecentLoginException が続く場合はエラーSnackBarを表示すること',
          (tester) async {
            setMobileView(tester);
            when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
              (_) async => const AccountDeletionPrecheck(
                requiresReauthentication: false,
                availableMethods: {ReauthMethod.google},
              ),
            );
            when(
              () => mockAuthService.deleteAccount(),
            ).thenThrow(const ReauthRequiresRecentLoginException());
            when(
              () => mockAuthService.reauthenticateWithGoogle(),
            ).thenAnswer((_) async {});

            await tester.pumpWidget(createTestWidget());
            await tester.pumpAndSettle();

            await proceedToStep2(tester);
            await tester.tap(
              find.byKey(const Key('account_deletion_step2_confirm')),
            );
            await tester.pumpAndSettle();

            await tester.tap(
              find.byKey(const Key('reauth_google_submit_button')),
            );
            await tester.pumpAndSettle();

            verify(() => mockAuthService.deleteAccount()).called(2);
            check(find.text('再認証が必要です')).findsOne();
          },
        );

        testWidgets(
          'deleteAccount が一般例外を投げた場合、処理中ダイアログを閉じてエラーSnackBarを表示すること',
          (tester) async {
            setMobileView(tester);
            when(() => mockAuthService.checkReauthRequirement()).thenAnswer(
              (_) async => const AccountDeletionPrecheck(
                requiresReauthentication: false,
                availableMethods: {ReauthMethod.password},
              ),
            );
            when(
              () => mockAuthService.deleteAccount(),
            ).thenThrow(const AppException.server(statusCode: 500));

            await tester.pumpWidget(createTestWidget());
            await tester.pumpAndSettle();

            await proceedToStep2(tester);
            await tester.tap(
              find.byKey(const Key('account_deletion_step2_confirm')),
            );
            await tester.pumpAndSettle();

            check(
              find.byKey(const Key('account_deletion_processing_dialog')),
            ).findsNothing();
            check(find.textContaining('サーバーエラー')).findsOne();
          },
        );

        Widget createWiredDeletionWidget({
          required HttpClientAdapter adapter,
          required MockFirebaseAuthRepository mockFirebaseRepo,
          required MockMemoRepository mockMemoRepo,
          MockQrScanHistoriesDao? mockQrDao,
          MockCacheManager? mockCacheManager,
          MockAnalyticsService? mockAnalytics,
        }) {
          final quietTalker = Talker(
            settings: TalkerSettings(useConsoleLogs: false),
          );
          final router = GoRouter(
            initialLocation: '/settings',
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          );

          return ProviderScope(
            overrides: [
              envConfigProvider.overrideWithValue(
                const EnvConfigState(
                  baseUrl: 'https://test.example.com',
                  imageBaseUrl: defaultImageBaseUrl,
                  aiModel: 'test-model',
                  connectTimeout: 10,
                  receiveTimeout: 15,
                  sendTimeout: 10,
                  useFirebaseAuth: true,
                  useAgentPlatform: true,
                ),
              ),
              isAuthenticatedProvider.overrideWithValue(true),
              loggerProvider.overrideWithValue(quietTalker),
              dioProvider.overrideWith((ref) {
                final dio = Dio(
                  BaseOptions(baseUrl: 'https://test.example.com'),
                )..httpClientAdapter = adapter;
                dio.interceptors.add(ref.watch(dioInterceptorProvider));
                return dio;
              }),
              firebaseAuthRepositoryProvider.overrideWithValue(
                mockFirebaseRepo,
              ),
              authRepositoryProvider.overrideWithValue(MockAuthRepository()),
              authStateProvider.overrideWith(
                _FakeDeletionAuthStateNotifier.new,
              ),
              tokenStorageProvider.overrideWithValue(MockTokenStorage()),
              storageServiceProvider.overrideWithValue(MockStorageService()),
              memoRepositoryProvider.overrideWithValue(mockMemoRepo),
              qrScanHistoriesDaoProvider.overrideWithValue(
                mockQrDao ?? MockQrScanHistoriesDao(),
              ),
              cacheManagerProvider.overrideWithValue(
                mockCacheManager ?? MockCacheManager(),
              ),
              analyticsServiceProvider.overrideWithValue(
                mockAnalytics ?? MockAnalyticsService(),
              ),
              clockProvider.overrideWithValue(
                () => DateTime.utc(2026, 11, 22, 9),
              ),
              lockSuppressionRunnerProvider.overrideWithValue(
                <T>(action, {isSuccess}) => action(),
              ),
              themeSchemeProvider.overrideWith(() => fakeThemeSchemeNotifier),
              textScaleProvider.overrideWith(() => fakeTextScaleNotifier),
              themeModeProvider.overrideWith(() => fakeThemeModeNotifier),
              localeProvider.overrideWith(() => fakeLocaleNotifier),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: [
                MockLocalizationsDelegate(mockL10n),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          );
        }

        testWidgets('実Dio+ProfileRepository連携: DELETE /users/me の 403 '
            '(requires-recent-login) で再認証後に再試行し退会完了すること', (tester) async {
          setMobileView(tester);
          registerFallbackValue(AnalyticsEvent.accountDeleted);

          final mockFirebaseRepo = MockFirebaseAuthRepository();
          final mockMemoRepo = MockMemoRepository();
          final mockQrDao = MockQrScanHistoriesDao();
          final mockCacheManager = MockCacheManager();
          final mockAnalytics = MockAnalyticsService();

          var deleteRequests = 0;
          final adapter = _StubHttpClientAdapter((options) async {
            if (options.method == 'GET' && options.path == '/users/me') {
              return ResponseBody.fromString(
                jsonEncode(const {
                  'name': '太郎',
                  'email': 'user@example.com',
                  'avatarUrl': '',
                }),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            if (options.method == 'DELETE' && options.path == '/users/me') {
              deleteRequests++;
              if (deleteRequests == 1) {
                return ResponseBody.fromString(
                  jsonEncode(const {'code': 'requires-recent-login'}),
                  403,
                  headers: {
                    Headers.contentTypeHeader: [Headers.jsonContentType],
                  },
                );
              }
              return ResponseBody.fromString(
                jsonEncode(const {'message': 'Account data deleted'}),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            return ResponseBody.fromString('', 404);
          });

          when(() => mockFirebaseRepo.currentUserId).thenReturn('uid-wired');
          when(() => mockFirebaseRepo.currentUserPhotoUrl).thenReturn(null);
          when(
            () => mockFirebaseRepo.needsRecentLogin(any<DateTime>()),
          ).thenReturn(false);
          when(
            mockFirebaseRepo.getAvailableReauthMethods,
          ).thenReturn({ReauthMethod.password});
          when(
            () => mockFirebaseRepo.currentUserEmail,
          ).thenReturn('user@example.com');
          when(
            () => mockFirebaseRepo.reauthenticateWithPassword(
              password: 'retry-password',
            ),
          ).thenAnswer((_) async {});
          when(mockFirebaseRepo.deleteAccount).thenAnswer((_) async {});
          when(
            () => mockAnalytics.logEvent(
              event: any(named: 'event'),
              parameters: any(named: 'parameters'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => mockMemoRepo.deleteAllMemosByUser('uid-wired'),
          ).thenAnswer((_) async => 1);
          when(mockQrDao.deleteAllHistories).thenAnswer((_) async => 0);
          when(
            () => mockCacheManager.clear(UserRepository.cacheKey),
          ).thenAnswer((_) async {});

          await tester.pumpWidget(
            createWiredDeletionWidget(
              adapter: adapter,
              mockFirebaseRepo: mockFirebaseRepo,
              mockMemoRepo: mockMemoRepo,
              mockQrDao: mockQrDao,
              mockCacheManager: mockCacheManager,
              mockAnalytics: mockAnalytics,
            ),
          );
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pumpAndSettle();

          // 1回目の DELETE 403 (requires-recent-login) により再認証モーダルが表示されること
          check(find.text('本人確認（再認証）')).findsOne();
          await tester.enterText(
            find.byKey(const Key('reauth_password_field')),
            'retry-password',
          );
          await tester.tap(
            find.byKey(const Key('reauth_password_submit_button')),
          );
          await tester.pumpAndSettle();

          check(deleteRequests).equals(2);
          verify(
            () => mockFirebaseRepo.reauthenticateWithPassword(
              password: 'retry-password',
            ),
          ).called(1);
          verify(mockFirebaseRepo.deleteAccount).called(1);
          verify(
            () => mockMemoRepo.deleteAllMemosByUser('uid-wired'),
          ).called(1);
        });

        testWidgets('実Dio+ProfileRepository連携: DELETE /users/me の通常の 403 は '
            '再認証モーダルを出さず権限エラーSnackBarを表示すること', (tester) async {
          setMobileView(tester);
          final mockFirebaseRepo = MockFirebaseAuthRepository();
          final mockMemoRepo = MockMemoRepository();

          final adapter = _StubHttpClientAdapter((options) async {
            if (options.method == 'GET' && options.path == '/users/me') {
              return ResponseBody.fromString(
                jsonEncode(const {
                  'name': '太郎',
                  'email': 'user@example.com',
                  'avatarUrl': '',
                }),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            if (options.method == 'DELETE' && options.path == '/users/me') {
              return ResponseBody.fromString(
                jsonEncode(const {'error': 'Forbidden'}),
                403,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            return ResponseBody.fromString('', 404);
          });

          when(() => mockFirebaseRepo.currentUserId).thenReturn('uid-403');
          when(() => mockFirebaseRepo.currentUserPhotoUrl).thenReturn(null);
          when(
            () => mockFirebaseRepo.needsRecentLogin(any<DateTime>()),
          ).thenReturn(false);
          when(
            mockFirebaseRepo.getAvailableReauthMethods,
          ).thenReturn({ReauthMethod.password});
          when(
            () => mockFirebaseRepo.currentUserEmail,
          ).thenReturn('user@example.com');

          await tester.pumpWidget(
            createWiredDeletionWidget(
              adapter: adapter,
              mockFirebaseRepo: mockFirebaseRepo,
              mockMemoRepo: mockMemoRepo,
            ),
          );
          await tester.pumpAndSettle();

          await proceedToStep2(tester);
          await tester.tap(
            find.byKey(const Key('account_deletion_step2_confirm')),
          );
          await tester.pumpAndSettle();

          check(find.text('本人確認（再認証）')).findsNothing();
          check(find.text('権限エラー')).findsOne();
          verifyNever(mockFirebaseRepo.deleteAccount);
        });

        testWidgets('アカウント削除実行中はボタンが無効化され、キャンセル後に再有効化されること', (tester) async {
          setMobileView(tester);
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final deleteButton = find.byKey(const Key('delete_account_button'));
          await tester.dragUntilVisible(
            deleteButton,
            find.byType(ListView),
            const Offset(0, -300),
          );

          await tester.tap(deleteButton);
          await tester.pumpAndSettle();

          check(
            find.byKey(const Key('account_deletion_step1_continue')),
          ).findsOne();
          check(tester.widget<OutlinedButton>(deleteButton).onPressed).isNull();

          await tester.tap(
            find.byKey(const Key('account_deletion_step1_cancel')),
          );
          await tester.pumpAndSettle();

          check(
            tester.widget<OutlinedButton>(deleteButton).onPressed,
          ).isNotNull();

          await tester.tap(deleteButton);
          await tester.pumpAndSettle();
          check(
            find.byKey(const Key('account_deletion_step1_continue')),
          ).findsOne();
          await tester.tap(
            find.byKey(const Key('account_deletion_step1_cancel')),
          );
          await tester.pumpAndSettle();
        });
      });
    });
  });
}
