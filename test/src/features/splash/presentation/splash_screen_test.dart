import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---

class MockAppLocalizations extends Mock implements AppLocalizations {}

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

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.appTitle).thenReturn('Flutter Sample App');
  });

  group('SplashScreenのテスト', () {
    test('コンストラクタでインスタンスが生成できること', () {
      check(const SplashScreen()).isNotNull();
    });

    testWidgets('初期表示のテスト: 背景グラデーションとロゴが表示されること', (tester) async {
      // 画面サイズを固定し、テスト終了時にリセットする
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              _MockLocalizationsDelegate(mockL10n),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ja')],
            home: const SplashScreen(),
          ),
        ),
      );
      await tester.pump();

      // Scaffold が表示されていること
      check(find.byType(Scaffold)).findsOne();

      // SplashLogo が表示されていること
      check(find.byType(SplashLogo)).findsOne();

      // ロゴ内のアイコンとテキストが表示されていること
      check(find.byIcon(Icons.flutter_dash)).findsOne();
      check(find.text('Flutter Sample App')).findsOne();
    });

    testWidgets('2秒経過後に SplashState が完了（true）に更新されること', (tester) async {
      // 画面サイズを固定し、テスト終了時にリセットする
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: [
              _MockLocalizationsDelegate(mockL10n),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ja')],
            home: const SplashScreen(),
          ),
        ),
      );
      await tester.pump();

      // 最初は false であること
      check(container.read(splashStateProvider)).equals(false);

      // 1秒経過（まだ false のはず）
      await tester.pump(const Duration(seconds: 1));
      check(container.read(splashStateProvider)).equals(false);

      // さらに1.5秒経過（合計2.5秒。2秒を超えたため、完了になる）
      await tester.pump(const Duration(milliseconds: 1500));
      check(container.read(splashStateProvider)).equals(true);
    });
  });
}
