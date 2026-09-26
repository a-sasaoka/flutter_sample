import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_controller.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:flutter_sample/src/features/chart/presentation/sales_chart_screen.dart';
import 'package:flutter_sample/src/features/chart/presentation/widgets/animated_sales_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget createWidgetUnderTest(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ja'),
        home: SalesChartScreen(),
      ),
    );
  }

  group('SalesChartScreen', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('SalesChartScreen can be instantiated', () {
      // カバレッジ計測でコンストラクタのコードを確実に実行させてカバーするため、あえて非constでインスタンス化します。
      // ignore: prefer_const_constructors
      final screen = SalesChartScreen();
      check(screen).isA<SalesChartScreen>();
    });

    testWidgets('初期表示でタイトル、サマリーカード、グラフが正しく表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // タイトルの確認
      check(find.text('売上推移チャート')).findsOne();

      // 期間切り替えSegmentedButtonの確認
      check(find.byType(SegmentedButton<SalesPeriod>)).findsOne();
      check(find.text('7日間')).findsOne();
      check(find.text('14日間')).findsOne();

      // サマリーカードの確認（初期状態: 7日間）
      check(find.text('合計売上')).findsOne();
      check(find.text('¥151,900')).findsOne();
      check(find.text('日別平均')).findsOne();
      check(find.text('¥21,700')).findsOne();

      // グラフウィジェットの確認
      check(find.byType(AnimatedSalesChart)).findsOne();
    });

    testWidgets('期間を14日間に切り替えたとき、サマリーカードの数値が更新されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // 「14日間」ボタンをタップ
      await tester.tap(find.text('14日間'));
      await tester.pumpAndSettle();

      // 状態が14日間に切り替わっていることを確認
      check(
        container.read(salesChartControllerProvider).period,
      ).equals(SalesPeriod.days14);

      // サマリーカードの数値が14日分の合計・平均に更新されていることを確認
      check(find.text('¥265,300')).findsOne();
      check(find.text('¥18,950')).findsOne();

      // 再度「7日間」ボタンをタップ
      await tester.tap(find.text('7日間'));
      await tester.pumpAndSettle();

      check(
        container.read(salesChartControllerProvider).period,
      ).equals(SalesPeriod.days7);
      check(find.text('¥151,900')).findsOne();
    });
  });
}
