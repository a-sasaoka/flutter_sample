import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen: スプラッシュ画面にインジケータが表示されること', (tester) async {
    // 1. ウィジェットの構築（ProviderScopeやL10nのモックすら不要！）
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // 2. 検証：CircularProgressIndicator が1つだけ存在するか
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // （おまけ）Scaffoldが土台として存在しているかも確認
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
