import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_display_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('ChartDisplayScreen Golden Tests', () {
    // グラフ画面をテスト用に構築する関数
    Widget buildChartDisplayForGolden({
      required ThemeMode themeMode,
      required ChartType chartType,
      bool isEmpty = false,
    }) {
      final container = ProviderContainer();

      // グラフの種類を設定します
      container.read(chartProvider.notifier).updateChartType(chartType);

      // データが空の状態をテストする場合はリセットします
      if (isEmpty) {
        container.read(chartProvider.notifier).reset();
      }

      return UncontrolledProviderScope(
        container: container,
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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const ChartDisplayScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'ChartDisplayScreen の描画 (折れ線/棒/円グラフ/空データ)',
      fileName: 'chart_display_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Line Chart - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.light,
                chartType: ChartType.line,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Bar Chart - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.dark,
                chartType: ChartType.bar,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Pie Chart - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.light,
                chartType: ChartType.pie,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty State - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.light,
                chartType: ChartType.line,
                isEmpty: true,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
