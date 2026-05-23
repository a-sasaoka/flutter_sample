import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('SplashScreenのテスト', () {
    testWidgets('初期表示のテスト: 背景グラデーションとロゴが表示されること', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Scaffold が表示されていること
      expect(find.byType(Scaffold), findsOneWidget);

      // SplashLogo が表示されていること
      expect(find.byType(SplashLogo), findsOneWidget);

      // ロゴ内のアイコンとテキストが表示されていること
      expect(find.byIcon(Icons.flutter_dash), findsOneWidget);
      expect(find.text('Flutter Sample App'), findsOneWidget);
    });

    testWidgets('2秒経過後に SplashState が完了（true）に更新されること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // 最初は false であること
      expect(container.read(splashStateProvider), isFalse);

      // 1秒経過（まだ false のはず）
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(splashStateProvider), isFalse);

      // さらに1.5秒経過（合計2.5秒。2秒を超えたため、完了になる）
      await tester.pump(const Duration(milliseconds: 1500));
      expect(container.read(splashStateProvider), isTrue);
    });
  });
}
