import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとFakeクラスの定義 ---

class MockAuthService extends Mock implements AuthService {}

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

    // エラーハンドラー経由で表示される翻訳キー
    when(() => mockL10n.errorUnknown).thenReturn('不明なエラー');
    when(() => mockL10n.errorOccurred).thenReturn('エラーが発生しました');
    when(() => mockL10n.settingsPreview).thenReturn('プレビュー');

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
      errorBuilder: (context, state) => Scaffold(
        body: Text('Navigated to ${state.uri}'),
      ),
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
        localeProvider.overrideWith(
          localeOverride ?? () => fakeLocaleNotifier,
        ),
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
        (
          tester,
        ) async {
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
          await tester.pumpWidget(
            createTestWidget(isAuthed: false),
          );
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

        testWidgets(
          'useAuth: false（自前認証）でもログアウトボタンが表示され signOut が呼ばれること',
          (tester) async {
            setMobileView(tester);

            await tester.pumpWidget(
              createTestWidget(useAuth: false),
            );
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
          },
        );

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
    });
  });
}
