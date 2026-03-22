import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モック & フェイク定義 ---
class MockAppLocalizations extends Mock implements AppLocalizations {}

class FakeAuthRepo extends FirebaseAuthRepository {
  FakeAuthRepo({this.onSignOut});
  final Future<void> Function()? onSignOut;
  @override
  User? build() => null;
  @override
  Future<void> signOut() async => onSignOut?.call();
}

class FakeThemeModeNotifier extends ThemeModeNotifier {
  FakeThemeModeNotifier({required this.initial, this.onSet, this.onToggle});
  final ThemeMode initial;
  final void Function(ThemeMode)? onSet;
  final void Function()? onToggle;

  @override
  Future<ThemeMode> build() async => initial;
  @override
  Future<void> set(ThemeMode mode) async => onSet?.call(mode);
  @override
  Future<void> toggleLightDark() async => onToggle?.call();
}

class FakeLocaleNotifier extends LocaleNotifier {
  FakeLocaleNotifier({required this.initial, this.onSet});
  final Locale? initial;
  final void Function(String?)? onSet;

  @override
  Future<Locale?> build() async => initial;
  @override
  Future<void> setLocale(String? languageCode) async =>
      onSet?.call(languageCode);
}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant _) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.settingsTitle).thenReturn('Settings');
    when(() => mockL10n.settingsThemeSection).thenReturn('Theme');
    when(() => mockL10n.settingsThemeSystem).thenReturn('System');
    when(() => mockL10n.settingsThemeLight).thenReturn('Light');
    when(() => mockL10n.settingsThemeDark).thenReturn('Dark');
    when(() => mockL10n.settingsThemeToggle).thenReturn('Toggle Dark Mode');
    when(() => mockL10n.settingsLocaleSection).thenReturn('Language');
    when(() => mockL10n.settingsLocaleSystem).thenReturn('System Default');
    when(() => mockL10n.settingsLocaleJa).thenReturn('Japanese');
    when(() => mockL10n.settingsLocaleEn).thenReturn('English');
    when(() => mockL10n.hello).thenReturn('Hello');
    when(() => mockL10n.logout).thenReturn('Logout');
    when(() => mockL10n.errorUnknown).thenReturn('Error Occurred');
  });

  Future<void> setupWidget(
    WidgetTester tester, {
    required AsyncValue<({ThemeMode theme, Locale? locale, GoRouter router})>
    config,
    bool useAuth = true,
    FirebaseAuthRepository? authRepo,
    ThemeModeNotifier? themeNotifier,
    LocaleNotifier? localeNotifier,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // テスト用のダミールーターを用意（未知のルート遷移でクラッシュさせない）
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      // ログアウト後の画面遷移（$LoginRouteなど）を安全にキャッチする
      errorBuilder: (context, state) =>
          const Scaffold(body: Text('Router Handled')),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWith(
            (ref) => config.when(
              data: (d) => d,
              loading: () =>
                  Completer<
                        ({ThemeMode theme, Locale? locale, GoRouter router})
                      >()
                      .future,
              error: Error.throwWithStackTrace,
            ),
          ),
          useFirebaseAuthProvider.overrideWithValue(useAuth),
          firebaseAuthRepositoryProvider.overrideWith(
            () => authRepo ?? FakeAuthRepo(),
          ),
          if (themeNotifier != null)
            themeModeProvider.overrideWith(() => themeNotifier),
          if (localeNotifier != null)
            localeProvider.overrideWith(() => localeNotifier),
        ],
        // MaterialApp.router に変更
        child: MaterialApp.router(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          routerConfig: testRouter,
        ),
      ),
    );

    await tester.pump();
    if (!config.isLoading) {
      await tester.pumpAndSettle();
    }
  }

  group('SettingsScreen Coverage 100% Test', () {
    final validData = AsyncValue.data((
      theme: ThemeMode.light,
      locale: const Locale('en'),
      router: GoRouter(routes: []),
    ));

    testWidgets('【正常系】UI表示とテーマ・言語の変更操作', (tester) async {
      ThemeMode? changedTheme;
      var isToggled = false;
      String? changedLocale;

      final fakeThemeNotifier = FakeThemeModeNotifier(
        initial: ThemeMode.light,
        onSet: (mode) => changedTheme = mode,
        onToggle: () => isToggled = true,
      );
      final fakeLocaleNotifier = FakeLocaleNotifier(
        initial: const Locale('en'),
        onSet: (code) => changedLocale = code,
      );

      await setupWidget(
        tester,
        config: validData,
        themeNotifier: fakeThemeNotifier,
        localeNotifier: fakeLocaleNotifier,
      );

      expect(find.text('Settings'), findsOneWidget);

      // 1. テーマ変更 (Dropdown) : 物理タップを避け、直接 onChanged を発火
      final themeDropdown = tester.widget<DropdownButton<ThemeMode>>(
        find.byType(DropdownButton<ThemeMode>),
      );
      themeDropdown.onChanged!(ThemeMode.dark);

      // Riverpod の状態が更新されたか確認
      expect(changedTheme, ThemeMode.dark);

      // 2. テーマ切替 (SwitchListTile) : 同様に直接 onChanged を発火
      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      switchTile.onChanged!(true);

      expect(isToggled, isTrue);

      // 3. 言語変更 (Dropdown) : 同様に直接 onChanged を発火
      final localeDropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      localeDropdown.onChanged!('ja');

      expect(changedLocale, 'ja');
    });

    testWidgets('【正常系】ログアウト成功時の処理', (tester) async {
      var signOutCalled = false;
      final authRepo = FakeAuthRepo(
        onSignOut: () async => signOutCalled = true,
      );

      await setupWidget(tester, config: validData, authRepo: authRepo);

      final logoutBtn = find.byKey(const Key('logout_button'));
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);

      await tester.pump();
      await tester.pumpAndSettle();

      expect(signOutCalled, isTrue);
    });

    testWidgets('【異常系】ログアウト失敗時にSnackBarが表示されること', (tester) async {
      final authRepo = FakeAuthRepo(
        onSignOut: () async =>
            throw Exception('SignOut Failed'), // これはErrorHandlerで変換される
      );

      await setupWidget(tester, config: validData, authRepo: authRepo);

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      // エラーハンドラーによって変換されたL10nのメッセージを検証する
      expect(find.textContaining('Error Occurred'), findsOneWidget);
    });

    testWidgets('【境界系】useAuthがfalseの時、ログアウトボタンが表示されないこと', (tester) async {
      await setupWidget(tester, config: validData, useAuth: false);
      expect(find.byKey(const Key('logout_button')), findsNothing);
    });

    testWidgets('【状態系】Loading状態の時にインジケータが表示されること', (tester) async {
      await setupWidget(tester, config: const AsyncValue.loading());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('【状態系】Error状態の時にエラーテキストが表示されること', (tester) async {
      await setupWidget(
        tester,
        config: const AsyncValue.error('Fetch Error', StackTrace.empty),
      );
      expect(find.textContaining('Error: Fetch Error'), findsOneWidget);
    });
  });
}
