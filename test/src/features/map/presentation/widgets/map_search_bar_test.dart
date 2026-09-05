import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/map_search_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapSearchBar Widget Tests', () {
    Widget buildTestWidget({
      required TextEditingController controller,
      required FocusNode focusNode,
      bool isLoading = false,
      ValueChanged<String>? onSubmitted,
      VoidCallback? onClear,
    }) {
      return MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            focusNode: focusNode,
            isLoading: isLoading,
            onSubmitted: onSubmitted ?? (_) {},
            onClear: onClear ?? () {},
          ),
        ),
      );
    }

    testWidgets('初期表示でヒントテキスト・検索アイコン・送信ボタンが表示されること', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          focusNode: focusNode,
        ),
      );
      await tester.pump();

      // ヒントテキストの確認
      check(find.text('住所やランドマークを検索')).findsOne();
      // 検索アイコンの確認
      check(find.byIcon(Icons.search)).findsOne();
      // 送信ボタンの確認
      check(find.byKey(const Key('mapSearchButton'))).findsOne();
      // 未入力時はクリアボタン非表示
      check(find.byKey(const Key('mapSearchClearButton'))).findsNothing();
    });

    testWidgets('テキスト入力時にクリアボタンが表示され、タップで onClear が呼ばれること', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      var clearCalled = false;
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          focusNode: focusNode,
          onClear: () => clearCalled = true,
        ),
      );
      await tester.pump();

      // テキストを入力
      await tester.enterText(
        find.byKey(const Key('mapSearchTextField')),
        '東京タワー',
      );
      await tester.pump();

      // クリアボタンが表示される
      check(find.byKey(const Key('mapSearchClearButton'))).findsOne();

      // クリアボタンをタップ
      await tester.tap(find.byKey(const Key('mapSearchClearButton')));
      await tester.pump();

      check(clearCalled).isTrue();
    });

    testWidgets('送信ボタンをタップすると onSubmitted が呼ばれること', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      String? submittedQuery;
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (query) => submittedQuery = query,
        ),
      );
      await tester.pump();

      // テキストを入力して送信ボタンをタップ
      await tester.enterText(
        find.byKey(const Key('mapSearchTextField')),
        'スカイツリー',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mapSearchButton')));
      await tester.pump();

      check(submittedQuery).equals('スカイツリー');
    });

    testWidgets('キーボードの確定(onSubmitted)でコールバックが呼ばれること', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      String? submittedQuery;
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (query) => submittedQuery = query,
        ),
      );
      await tester.pump();

      // テキストを入力して確定
      await tester.enterText(
        find.byKey(const Key('mapSearchTextField')),
        '富士山',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      check(submittedQuery).equals('富士山');
    });

    testWidgets('isLoading が true のときローディングインジケータが表示され送信ボタンが非表示になること', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          focusNode: focusNode,
          isLoading: true,
        ),
      );
      await tester.pump();

      // ローディングインジケータが表示される
      check(find.byType(CircularProgressIndicator)).findsOne();
      // 送信ボタンは非表示
      check(find.byKey(const Key('mapSearchButton'))).findsNothing();
    });
  });
}
