import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとFakeクラスの定義 ---

class MockAuthService extends Mock implements AuthService {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

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
  late FakeThemeModeNotifier fakeThemeModeNotifier;
  late FakeLocaleNotifier fakeLocaleNotifier;

  setUp(() {
    mockAuthService = MockAuthService();
    mockL10n = MockAppLocalizations();

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
    testWidgets('テーマ設定が読み込み中の場合でも、デフォルト値（システム）で安全にフォールバック表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(themeModeOverride: LoadingThemeModeNotifier.new),
      );
      await tester.pump();

      check(find.text('システム')).findsOne();
    });

    testWidgets('言語設定が読み込み中の場合でも、デフォルト値（システム依存）で安全にフォールバック表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(localeOverride: LoadingLocaleNotifier.new),
      );
      await tester.pump();

      check(find.text('システム依存')).findsOne();
    });

    group('データ取得完了後 (Data状態)', () {
      testWidgets('UIが正しくレンダリングされること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        check(find.text('設定')).findsOne();
        check(find.text('テーマ設定')).findsOne();
        check(find.text('ライト')).findsOne();
        check(find.text('言語設定')).findsOne();
        check(find.text('プレビュー: こんにちは！')).findsOne();
      });

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
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 英語を選択
        await tester.tap(find.text('英語'));
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
          // ビューポートサイズを固定
          tester.view.physicalSize = const Size(1080, 1920);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

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
            tester.view.physicalSize = const Size(1080, 1920);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

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
          tester.view.physicalSize = const Size(1080, 1920);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

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
