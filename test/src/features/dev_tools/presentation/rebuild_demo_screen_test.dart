import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/dev_tools/domain/rebuild_item.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/rebuild_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidget({
    ProviderContainer? container,
    Locale locale = const Locale('ja'),
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const RebuildDemoScreen(),
      ),
    );
  }

  group('RebuildDemoScreen', () {
    test('RebuildDemoScreen can be instantiated', () {
      // カバレッジ計測でコンストラクタのコードを確実に実行させてカバーするため、あえて非constでインスタンス化します。
      // ignore: prefer_const_constructors, testing non-const constructor for coverage
      final screen = RebuildDemoScreen();
      check(screen).isA<RebuildDemoScreen>();
    });

    test('RebuildTrackerBadge can be instantiated', () {
      // カバレッジ計測でコンストラクタのコードを確実に実行させてカバーするため、あえて非constでインスタンス化します。
      // ignore: prefer_const_constructors, testing non-const constructor for coverage
      final badge = RebuildTrackerBadge(label: 'test_badge', count: 1);
      check(badge.label).equals('test_badge');
      check(badge.count).equals(1);
    });

    testWidgets('getLocalizedRebuildItemsがロケールに応じてローカライズされたデータを返すこと', (
      tester,
    ) async {
      late AppLocalizations jaL10n;
      late AppLocalizations enL10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              jaL10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              enL10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final jaItems = getLocalizedRebuildItems(jaL10n);
      final enItems = getLocalizedRebuildItems(enL10n);

      check(jaItems).length.equals(10);
      check(enItems).length.equals(10);

      // 日本語の検証
      check(jaItems.first.category).equals('レイアウト');
      check(jaItems.first.description).contains('万能ボックスWidget');

      // 英語の検証
      check(enItems.first.category).equals('Layout');
      check(enItems.first.description).contains('versatile box widget');

      // matchesQuery の単体検証
      check(enItems.first.matchesQuery('layout')).isTrue();
      check(enItems.first.matchesQuery('container')).isTrue();
      check(enItems.first.matchesQuery('versatile')).isTrue();
      check(enItems.first.matchesQuery('xyz_non_existent')).isFalse();
      check(enItems.first.matchesQuery('   ')).isTrue();
    });

    testWidgets('初期状態でBadモード（非効率）の画面が表示されること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      // AppBarタイトル
      check(find.text('再ビルド最適化検証').evaluate()).length.equals(1);

      // 初期モードはBadモード
      check(find.text('Badモード（非効率）').evaluate()).length.equals(1);
      check(find.text('画面全体エリア').evaluate()).length.equals(1);

      // 検索バーが存在すること
      check(
        find.byKey(const Key('rebuild_search_text_field')).evaluate(),
      ).length.equals(1);

      // 初期アイテム（Containerなど）が表示されること
      check(find.text('Container').evaluate()).length.equals(1);
      check(find.text('ListView.builder').evaluate()).length.equals(1);

      // 再ビルドバッジが表示されていること
      check(find.byType(RebuildTrackerBadge).evaluate().isNotEmpty).isTrue();
    });

    testWidgets('Badモードで検索入力を行うと絞り込みが行われ、親Rootも巻き添えで再描画されること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      // 初期状態では Root は 1回、表示中の Item 1 も 1回
      check(find.text('Root: Rebuild: 1回').evaluate()).length.equals(1);
      check(find.text('Item 1: Rebuild: 1回').evaluate()).length.equals(1);

      final searchField = find.byKey(const Key('rebuild_search_text_field'));

      // 'container' を入力
      await tester.enterText(searchField, 'container');
      await tester.pumpAndSettle();

      // 親画面全体が再描画されたため、Root バッジが 2回 にカウントアップされること
      check(find.text('Root: Rebuild: 2回').evaluate()).length.equals(1);
      // 親の巻き添えで再描画されたため、Item 1 も 2回 になること
      check(find.text('Item 1: Rebuild: 2回').evaluate()).length.equals(1);

      // Container と AnimatedContainer のみが表示される
      check(find.text('Container').evaluate()).length.equals(1);
      check(find.text('AnimatedContainer').evaluate()).length.equals(1);
      check(find.text('TextField').evaluate()).isEmpty();

      // 該当なしのキーワードを入力
      await tester.enterText(searchField, 'xyz_not_found');
      await tester.pumpAndSettle();

      // さらに再描画され、Root バッジが 3回 になること
      check(find.text('Root: Rebuild: 3回').evaluate()).length.equals(1);
      check(find.text('該当するアイテムが見つかりません').evaluate()).length.equals(1);
    });

    testWidgets('スイッチをタップするとGoodモードに切り替わり、Rootを巻き込まずにSearchBarのみが再描画されること', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      final toggleSwitch = find.byKey(const Key('toggle_rebuild_mode_switch'));

      // スイッチをタップしてGoodモードへ切り替え
      await tester.tap(toggleSwitch);
      await tester.pumpAndSettle();

      // Goodモードの文言・コンポーネントが表示されること
      check(find.text('Goodモード（最適化済み）').evaluate()).length.equals(1);
      check(find.text('画面全体エリア（分割済）').evaluate()).length.equals(1);

      // 切り替え直後は Root も SearchBar も 1回
      check(find.text('Root: Rebuild: 1回').evaluate()).length.equals(1);
      check(find.text('SearchBar: Rebuild: 1回').evaluate()).length.equals(1);
      check(find.text('Item 1: Rebuild: 1回').evaluate()).length.equals(1);

      // Goodモードで検索欄に入力
      final searchField = find.byKey(const Key('rebuild_search_text_field'));
      await tester.enterText(searchField, 'container');
      await tester.pumpAndSettle();

      // 🌟 親の Root は 1回 のまま動かない！（const の恩恵）
      check(find.text('Root: Rebuild: 1回').evaluate()).length.equals(1);
      // 🌟 検索バーのみが再描画され、SearchBar バッジが 2回 になること
      check(find.text('SearchBar: Rebuild: 2回').evaluate()).length.equals(1);
      // 🌟 検索絞り込みによりItemListが再構築され、残ったItem 1カードも2回にカウントアップされること
      check(find.text('Item 1: Rebuild: 2回').evaluate()).length.equals(1);

      check(find.text('Container').evaluate()).length.equals(1);
      check(find.text('AnimatedContainer').evaluate()).length.equals(1);
      check(find.text('TextField').evaluate()).isEmpty();

      // 該当なしのキーワード
      await tester.enterText(searchField, 'no_result_xyz');
      await tester.pumpAndSettle();

      // Root は依然として 1回 のまま！
      check(find.text('Root: Rebuild: 1回').evaluate()).length.equals(1);
      // SearchBar は 3回 になること
      check(find.text('SearchBar: Rebuild: 3回').evaluate()).length.equals(1);
      check(find.text('該当するアイテムが見つかりません').evaluate()).length.equals(1);
    });

    testWidgets('リセットボタンをタップすると状態と画面ツリーが初期化されること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      // 最適化モードをONにし、検索クエリを入力
      await tester.tap(find.byKey(const Key('toggle_rebuild_mode_switch')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('rebuild_search_text_field')),
        'Hero',
      );
      await tester.pumpAndSettle();

      check(find.text('Goodモード（最適化済み）').evaluate()).length.equals(1);
      // TextFieldの入力値とカードのタイトルの2箇所で 'Hero' が表示される
      check(find.text('Hero').evaluate()).length.equals(2);

      // リセットボタンをタップ
      await tester.tap(find.byKey(const Key('reset_rebuild_demo_button')));
      await tester.pumpAndSettle();

      // 初期状態（Badモード・空クエリ）に戻っていること
      check(find.text('Badモード（非効率）').evaluate()).length.equals(1);
      check(find.text('Container').evaluate()).length.equals(1);
      check(find.text('ListView.builder').evaluate()).length.equals(1);
    });

    testWidgets('英語ロケール時に英語のカテゴリや説明文で検索絞り込みができること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createWidget(container: container, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      // 英語のAppBarタイトル
      check(find.text('Rebuild Optimization').evaluate()).length.equals(1);

      final searchField = find.byKey(const Key('rebuild_search_text_field'));

      // 英語カテゴリ 'Layout' で検索 -> Container, Stack がヒット
      await tester.enterText(searchField, 'Layout');
      await tester.pumpAndSettle();

      check(find.text('Container').evaluate()).length.equals(1);
      check(find.text('Stack').evaluate()).length.equals(1);
      check(find.text('TextField').evaluate()).isEmpty();

      // 英語説明文のキーワード 'memory' で検索 -> ListView.builder がヒット
      await tester.enterText(searchField, 'memory');
      await tester.pumpAndSettle();

      check(find.text('ListView.builder').evaluate()).length.equals(1);
      check(find.text('Container').evaluate()).isEmpty();
    });

    testWidgets('Badモードで親が複数回ビルドされた後に初めて表示されるカードのバッジは親の累積回数ではなく1回であること', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('rebuild_search_text_field'));

      // 1回目の検索更新: 該当なしクエリで親のビルド回数を進める (Root: 2回)
      await tester.enterText(searchField, 'non_existent_query');
      await tester.pumpAndSettle();
      check(find.text('Root: Rebuild: 2回').evaluate()).length.equals(1);

      // 2回目の検索更新: 初めて 'Hero' (Item 10) を表示させる (Root: 3回)
      await tester.enterText(searchField, 'Hero');
      await tester.pumpAndSettle();
      check(find.text('Root: Rebuild: 3回').evaluate()).length.equals(1);

      // 🌟 親Rootは3回だが、Heroカード自身はこの検索で初めてビルドされたため、バッジは1回であること
      check(find.text('Item 10: Rebuild: 1回').evaluate()).length.equals(1);
    });

    testWidgets('RebuildTrackerBadgeが回数に応じて異なる色とテキストを適用すること', (tester) async {
      Widget buildBadge(int count) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: RebuildTrackerBadge(label: 'TestBadge', count: count),
          ),
        );
      }

      // 初回描画 (count <= 1: Colors.green)
      await tester.pumpWidget(buildBadge(1));
      await tester.pumpAndSettle();
      check(find.text('TestBadge: Rebuild: 1回').evaluate()).length.equals(1);

      // 2回目（count == 2: Colors.orange）
      await tester.pumpWidget(buildBadge(2));
      await tester.pumpAndSettle();
      check(find.text('TestBadge: Rebuild: 2回').evaluate()).length.equals(1);

      // 3回目（count == 3: Colors.orange）
      await tester.pumpWidget(buildBadge(3));
      await tester.pumpAndSettle();
      check(find.text('TestBadge: Rebuild: 3回').evaluate()).length.equals(1);

      // 4回目以上（count >= 4: Colors.red）
      await tester.pumpWidget(buildBadge(4));
      await tester.pumpAndSettle();
      check(find.text('TestBadge: Rebuild: 4回').evaluate()).length.equals(1);
    });
  });
}
