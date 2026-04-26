import 'dart:async';

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

// --- モックとFakeクラスの定義 ---

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class FakeThemeModeNotifier extends ThemeModeNotifier {
  ThemeMode? calledSetMode;
  bool calledToggle = false;

  @override
  Future<ThemeMode> build() async => ThemeMode.system;

  @override
  Future<void> set(ThemeMode mode) async {
    calledSetMode = mode;
  }

  @override
  Future<void> toggleLightDark() async {
    calledToggle = true;
  }
}

class FakeLocaleNotifier extends LocaleNotifier {
  String? calledSetLocale;

  @override
  Future<Locale?> build() async => null;

  @override
  Future<void> setLocale(String? locale) async {
    calledSetLocale = locale;
  }
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
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

// 状態を制御するためのEnum
enum ConfigState { loading, error, data }

void main() {
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockAppLocalizations mockL10n;
  late FakeThemeModeNotifier fakeThemeModeNotifier;
  late FakeLocaleNotifier fakeLocaleNotifier;

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockL10n = MockAppLocalizations();

    fakeThemeModeNotifier = FakeThemeModeNotifier();
    fakeLocaleNotifier = FakeLocaleNotifier();

    // 翻訳モックの設定
    when(() => mockL10n.settingsTitle).thenReturn('設定');
    when(() => mockL10n.settingsThemeSection).thenReturn('テーマ設定');
    when(() => mockL10n.settingsThemeSystem).thenReturn('システム依存');
    when(() => mockL10n.settingsThemeLight).thenReturn('ライトモード');
    when(() => mockL10n.settingsThemeDark).thenReturn('ダークモード');
    when(() => mockL10n.settingsThemeToggle).thenReturn('ダークモードにする');
    when(() => mockL10n.settingsLocaleSection).thenReturn('言語設定');
    when(() => mockL10n.settingsLocaleSystem).thenReturn('システム依存');
    when(() => mockL10n.settingsLocaleJa).thenReturn('日本語');
    when(() => mockL10n.settingsLocaleEn).thenReturn('English');
    when(() => mockL10n.hello).thenReturn('こんにちは！');
    when(() => mockL10n.logout).thenReturn('ログアウト');
    when(() => mockL10n.close).thenReturn('閉じる');

    // エラーハンドラー経由で表示される翻訳キー
    when(() => mockL10n.errorUnknown).thenReturn('不明なエラー');

    // リポジトリメソッドのスタブ
    when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
  });

  Widget createTestWidget({
    ConfigState configState = ConfigState.data,
    bool useAuth = true,
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
        appConfigProvider.overrideWith((ref) async {
          if (configState == ConfigState.loading) {
            // Loadingをシミュレートするため、終わらないFutureを返す
            return Completer<
                  ({Locale? locale, GoRouter router, ThemeMode theme})
                >()
                .future;
          } else if (configState == ConfigState.error) {
            // 例外を投げてError状態を再現
            throw Exception('Config Load Error');
          } else {
            // Data状態としてレコード型を返す
            return (
              locale: const Locale('ja'),
              router: router,
              theme: ThemeMode.light,
            );
          }
        }),
        useFirebaseAuthProvider.overrideWithValue(useAuth),
        firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
        themeModeProvider.overrideWith(() => fakeThemeModeNotifier),
        localeProvider.overrideWith(() => fakeLocaleNotifier),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('ローディング状態の時、CircularProgressIndicator が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(configState: ConfigState.loading),
      );

      // 初期ルーティングのマイクロタスクを消化するために少し進める
      await tester.pump();
      await tester.pump();

      // iOS環境等でCupertinoActivityIndicatorに化ける可能性も考慮
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CircularProgressIndicator ||
              w.runtimeType.toString() == 'CupertinoActivityIndicator',
        ),
        findsOneWidget,
      );
    });

    testWidgets('エラー状態の時、エラーメッセージが表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(configState: ConfigState.error),
      );

      // エラー画面が完全に描画されるまで待機
      await tester.pumpAndSettle();

      expect(find.textContaining('Config Load Error'), findsOneWidget);
    });

    group('データ取得完了後 (Data状態)', () {
      testWidgets('UIが正しくレンダリングされること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('設定'), findsOneWidget);
        expect(find.text('テーマ設定'), findsOneWidget);
        expect(find.text('ライトモード'), findsOneWidget);
        expect(find.text('言語設定'), findsOneWidget);
        expect(find.text('こんにちは！'), findsOneWidget);
      });

      testWidgets('テーマのDropdownを変更した時、ThemeModeNotifierのsetが呼ばれること', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButton<ThemeMode>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('ダークモード').last);
        await tester.pumpAndSettle();

        expect(fakeThemeModeNotifier.calledSetMode, ThemeMode.dark);
      });

      testWidgets('テーマのSwitchを切り替えた時、toggleLightDarkが呼ばれること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(fakeThemeModeNotifier.calledToggle, isTrue);
      });

      testWidgets('言語のDropdownを変更した時、LocaleNotifierのsetLocaleが呼ばれること', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('English').last);
        await tester.pumpAndSettle();

        expect(fakeLocaleNotifier.calledSetLocale, 'en');
      });

      group('ログアウトボタン (useAuthの分岐)', () {
        testWidgets('useAuth == false の場合、ログアウトボタンは表示されないこと', (tester) async {
          await tester.pumpWidget(
            createTestWidget(useAuth: false),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('logout_button')), findsNothing);
        });

        testWidgets('useAuth == true でログアウト成功時、LoginRouteに遷移すること', (
          tester,
        ) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final logoutButton = find.byKey(const Key('logout_button'));

          // 画面サイズによってはログアウトボタンが隠れている可能性があるため、見える位置までスクロールする
          await tester.ensureVisible(logoutButton);

          await tester.tap(logoutButton);
          await tester.pumpAndSettle();

          verify(() => mockAuthRepo.signOut()).called(1);
          expect(find.textContaining('Navigated to'), findsOneWidget);
        });

        testWidgets('ログアウト時に例外が発生した場合、SnackBarでエラーが表示されること', (tester) async {
          final exception = Exception('Logout failed!');
          when(() => mockAuthRepo.signOut()).thenThrow(exception);

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          final logoutButton = find.byKey(const Key('logout_button'));

          // 画面サイズによってはログアウトボタンが隠れている可能性があるため、見える位置までスクロールする
          await tester.ensureVisible(logoutButton);

          await tester.tap(logoutButton);
          await tester.pump();

          verify(() => mockAuthRepo.signOut()).called(1);

          // ErrorHandler経由で例外のメッセージが「不明なエラー」に翻訳されて出力されることを確認
          expect(find.textContaining('不明なエラー'), findsOneWidget);
          expect(find.textContaining('Navigated to'), findsNothing);
        });
      });
    });
  });
}
