// ignore_for_file: prefer_const_constructors, document_ignores
import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/services/app_lock_state_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/empty_state_widget.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_list_shimmer.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モッククラスの定義 ---

class MockMemoRepository extends Mock implements MemoRepository {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockTalker extends Mock implements Talker {}

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
  late MockMemoRepository mockMemoRepository;
  late MockAppLocalizations mockL10n;
  late MockTalker mockTalker;

  setUp(() {
    mockMemoRepository = MockMemoRepository();
    mockL10n = MockAppLocalizations();
    mockTalker = MockTalker();

    // L10nのスタブ設定
    when(() => mockL10n.memoTitle).thenReturn('メモ');
    when(() => mockL10n.memoEmpty).thenReturn('メモがありません');
    when(() => mockL10n.errorUnknown).thenReturn('エラーが発生しました');
    when(() => mockL10n.memoInputTitleHint).thenReturn('タイトル');
    when(() => mockL10n.memoInputContentHint).thenReturn('内容');
    when(() => mockL10n.memoAdd).thenReturn('メモを追加');
    when(() => mockL10n.memoSave).thenReturn('保存');
    when(() => mockL10n.memoSyncing).thenReturn('同期中');
    when(() => mockL10n.memoSynced).thenReturn('同期済み');
    when(() => mockL10n.memoUnsynced).thenReturn('未同期');
    when(() => mockL10n.memoDeleteConfirm).thenReturn('削除しますか？');
    when(() => mockL10n.close).thenReturn('閉じる');
    when(() => mockL10n.delete).thenReturn('削除');
    when(() => mockL10n.memoSearchHint).thenReturn('検索...');
    when(() => mockL10n.memoSortCreatedAtDesc).thenReturn('作成：新しい順');
    when(() => mockL10n.memoSortCreatedAtAsc).thenReturn('作成：古い順');
    when(() => mockL10n.memoSortUpdatedAtDesc).thenReturn('更新：新しい順');
    when(() => mockL10n.memoSortUpdatedAtAsc).thenReturn('更新：古い順');
    when(() => mockL10n.memoSortTitleAsc).thenReturn('タイトル：昇順');
    when(() => mockL10n.memoSortTitleDesc).thenReturn('タイトル：降順');
    when(() => mockL10n.memoCategoryAll).thenReturn('すべて');
    when(() => mockL10n.memoCategoryWork).thenReturn('仕事');
    when(() => mockL10n.memoCategoryPersonal).thenReturn('個人');
    when(() => mockL10n.memoCategoryIdea).thenReturn('アイデア');
    when(() => mockL10n.memoCategorySelect).thenReturn('カテゴリ');
    when(() => mockL10n.memoFilterUnsyncedOnly).thenReturn('未同期のみ');
    when(() => mockL10n.memoSearchEmpty).thenReturn('一致するメモがありません');
    when(() => mockL10n.memoClearFilter).thenReturn('条件をクリア');

    // デフォルトのスタブ設定
    when(
      () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
    ).thenAnswer((_) async {});
    when(
      () =>
          mockTalker.handle(any<Object>(), any<StackTrace?>(), any<String?>()),
    ).thenAnswer((_) {});
    when(
      () => mockMemoRepository.watchAllMemos(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockMemoRepository.watchFilteredMemos(
        any(),
        query: any(named: 'query'),
        category: any(named: 'category'),
        unsyncedOnly: any(named: 'unsyncedOnly'),
      ),
    ).thenAnswer((_) => Stream.value([]));
  });

  /// テスト環境のセットアップヘルパー
  Future<void> setupWidget(WidgetTester tester, {bool isOnline = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test_user_id'),
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
          isOnlineProvider.overrideWithValue(isOnline),
          loggerProvider.overrideWithValue(mockTalker),
          isAppUnlockedProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MemoScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  group('MemoScreen', () {
    testWidgets('ローディング状態が正しく表示されること', (tester) async {
      final completer = Completer<List<MemoModel>>();
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => completer.future.asStream());

      await setupWidget(tester);

      check(find.byType(MemoListShimmer)).findsOne();
    });

    testWidgets('エラー状態が正しく表示されること', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.error(Exception('Test Error')));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('エラーが発生しました')).findsOne();
    });

    testWidgets('データが空の場合、空の状態が表示されること', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('メモがありません')).findsOne();
      check(find.byType(EmptyStateWidget)).findsOne();
    });

    testWidgets('データが存在する場合、カードリストとして表示されること', (tester) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'タイトル1',
          content: '内容1',
          createdAt: now,
          updatedAt: now,
          isSynced: true,
        ),
      ];
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('タイトル1')).findsOne();
      check(find.text('内容1')).findsOne();
      check(find.text('同期済み')).findsOne();
      check(find.byIcon(Icons.cloud_done)).findsOne();
    });

    testWidgets('FABを押すとボトムシートが開き、メモを追加できること', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockMemoRepository.addMemo(any(), any(), any()),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // FABをタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ボトムシートが表示されていることを確認（検索バー + タイトル + 内容の3つ）
      check(find.byType(TextField)).findsExactly(3);

      await tester.enterText(find.widgetWithText(TextField, 'タイトル'), '新タイトル');
      await tester.enterText(find.widgetWithText(TextField, '内容'), '新内容');

      // 保存ボタンをタップ
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.addMemo('新タイトル', '新内容', 'test_user_id'),
      ).called(1);
      // ボトムシートが閉じていることを確認（検索バーだけが残っている）
      check(find.byType(TextField)).findsOne();
    });

    testWidgets('削除ボタンを押すとダイアログが表示され、キャンセルすると何も起きないこと', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '消さないメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([memo]));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsOne();

      // 「閉じる」ボタンをタップしてキャンセル
      await tester.tap(find.widgetWithText(TextButton, '閉じる'));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsNothing();
      verifyNever(() => mockMemoRepository.deleteMemo(any(), any()));
    });

    testWidgets('削除ボタンを押すとダイアログが表示され、実行すると削除処理が呼ばれること', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '消すメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([memo]));
      when(
        () => mockMemoRepository.deleteMemo(any(), any()),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 削除アイコンをタップ
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsOne();

      // 「削除」ボタンをタップ
      await tester.tap(find.widgetWithText(TextButton, '削除'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.deleteMemo('1', 'test_user_id'),
      ).called(1);
    });

    testWidgets('同期ボタンを押すと同期処理が呼ばれること', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      // build時に1回、同期ボタンタップ時に1回で合計2回
      verify(
        () => mockMemoRepository.fetchAndMergeRemoteMemos('test_user_id'),
      ).called(2);
    });

    testWidgets('同期ボタンを押してエラーが発生した場合、エラー通知が表示されること', (tester) async {
      var callCount = 0;
      final syncException = Exception('同期エラー');
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockMemoRepository.fetchAndMergeRemoteMemos(any())).thenAnswer(
        (_) async {
          if (callCount++ == 0) {
            // build時の自動同期は成功
            return;
          } else {
            // ボタンタップ時はエラー
            throw syncException;
          }
        },
      );

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      check(find.byType(SnackBar)).findsOne();
      check(find.text('エラーが発生しました')).findsOne();
      verify(
        () => mockTalker.handle(
          syncException,
          any(that: isA<StackTrace>()),
          '手動同期中にエラーが発生しました',
        ),
      ).called(1);
    });

    testWidgets('引っ張って更新（Pull to Refresh）が動作すること', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // リストを下に引っ張る
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump(); // インジケータ表示開始
      await tester.pump(const Duration(seconds: 1)); // 完了待ち
      await tester.pumpAndSettle();

      // リロードのために fetchAndMergeRemoteMemos が再度呼ばれることを確認
      // (初回 build 時に 1 回、onRefresh 時に 1 回で合計 2 回)
      verify(
        () => mockMemoRepository.fetchAndMergeRemoteMemos('test_user_id'),
      ).called(2);
    });

    testWidgets('検索キーワードを入力した際、部分一致するメモだけが表示されること（インクリメンタルサーチ）', (
      tester,
    ) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'りんごのメモ',
          content: '赤くて甘い果物',
          createdAt: now,
          updatedAt: now,
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'バナナのメモ',
          content: '黄色くて長い果物',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));
      when(
        () => mockMemoRepository.watchFilteredMemos(
          any(),
          query: any(named: 'query'),
          category: any(named: 'category'),
          unsyncedOnly: any(named: 'unsyncedOnly'),
        ),
      ).thenAnswer((invocation) {
        final query = invocation.namedArguments[#query] as String?;
        if (query == null || query.isEmpty) {
          return Stream.value(memoList);
        }
        return Stream.value(
          memoList.where((m) => m.title.contains(query)).toList(),
        );
      });

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 初期状態では両方表示されている
      check(find.text('りんごのメモ')).findsOne();
      check(find.text('バナナのメモ')).findsOne();

      // 検索バーに「りんご」を入力
      await tester.enterText(find.byType(TextField).first, 'りんご');
      await tester.pump();

      // 400ms 経過前の 399ms 時点ではデバウンス発火前のため「バナナのメモ」もまだ表示されている
      await tester.pump(const Duration(milliseconds: 399));
      check(find.text('バナナのメモ')).findsOne();

      // 残り 1ms 進めて 400ms に達するとデバウンスが発火し絞り込まれる
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      // 「りんご」のみ表示され、「バナナ」は非表示になる
      check(find.text('りんごのメモ')).findsOne();
      check(find.text('バナナのメモ')).findsNothing();

      // クリアボタンをタップして検索をリセット
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 再び両方表示される
      check(find.text('りんごのメモ')).findsOne();
      check(find.text('バナナのメモ')).findsOne();
    });

    testWidgets('ソート順を切り替えた際、指定したルールに従ってリストが並び替わること', (tester) async {
      final t1 = DateTime(2026, 5, 10, 10);
      final t2 = DateTime(2026, 5, 10, 11);
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'B_Memo',
          content: 'content B',
          createdAt: t1,
          updatedAt: t2,
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'A_Memo',
          content: 'content A',
          createdAt: t2,
          updatedAt: t1,
        ),
      ];
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // デフォルトは「作成日時：新しい順」(A_Memoの方がt2で新しいので上に来るはず)
      var posA = tester.getTopLeft(find.text('A_Memo')).dy;
      var posB = tester.getTopLeft(find.text('B_Memo')).dy;
      check(posA < posB).equals(true); // A_Memo の方が Y 座標が小さく、上にある

      // ソートボタン（PopupMenuButton）をタップ
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // 「作成日時：古い順」を選択
      await tester.tap(find.text('作成：古い順'));
      await tester.pumpAndSettle();

      // B_Memo (t1) の方が古いので上に来るはず
      posA = tester.getTopLeft(find.text('A_Memo')).dy;
      posB = tester.getTopLeft(find.text('B_Memo')).dy;
      check(posB < posA).equals(true); // B_Memo の方が上にある
    });

    testWidgets('画面外タップでキーボードが閉じること(一覧画面および追加ボトムシート)', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));
      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 1. 一覧画面でのテスト: 検索窓をタップしてフォーカスを当てる
      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      var context = tester.element(searchField);
      check(FocusScope.of(context).focusedChild).isNotNull();

      // 2. AppBar(画面外)をタップしてフォーカスが外れるか確認
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();
      check(FocusScope.of(context).focusedChild).isNull();

      // 3. 追加ボトムシートでのテスト: FABをタップしてボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ボトムシート内の最初の入力欄(タイトルTextField)
      final titleField = find.widgetWithText(TextField, 'タイトル');
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      context = tester.element(titleField);
      check(FocusScope.of(context).focusedChild).isNotNull();

      // 4. ボトムシート内の余白部分(GestureDetector)をタップしてフォーカスが外れるか確認
      // GestureDetectorを特定するためにボトムシートの要素をタップします
      await tester.tap(find.text('メモを追加').last);
      await tester.pumpAndSettle();
      check(FocusScope.of(context).focusedChild).isNull();
    });

    testWidgets('外部から検索クエリが変更された場合に入力欄の文字が同期して更新されること', (tester) async {
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([]));

      // Riverpodのコンテナに直接アクセスして状態を操作できるようにするため、
      // setupWidget ではなくここで個別にProviderScopeを準備します。
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test_user_id'),
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: [
              MockLocalizationsDelegate(mockL10n),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MemoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 最初は入力欄は空
      final searchField = find.byType(TextField).first;
      check(tester.widget<TextField>(searchField).controller?.text).equals('');

      // 外部(プロバイダー)から検索キーワードを「外部変更キーワード」に変更する
      container.read(memoSearchQueryProvider.notifier).setQuery('外部変更キーワード');
      await tester.pumpAndSettle();

      // 入力欄の文字が「外部変更キーワード」に自動で切り替わっていることを確認
      check(
        tester.widget<TextField>(searchField).controller?.text,
      ).equals('外部変更キーワード');

      container.dispose();
    });

    testWidgets('action=create かつ ロック解除状態の場合、自動的に新規追加ダイアログが表示されること', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/memos?action=create',
        routes: [
          GoRoute(
            path: '/memos',
            builder: (context, state) =>
                MemoScreen(action: state.uri.queryParameters['action']),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test_user_id'),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            loggerProvider.overrideWithValue(mockTalker),
            isAppUnlockedProvider.overrideWithValue(true),
          ],
          child: MaterialApp.router(
            localizationsDelegates: [
              MockLocalizationsDelegate(mockL10n),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボトムシート内の「保存」ボタンが表示されていることを確認
      check(find.text('保存')).findsOne();
    });

    testWidgets('action=create かつ ロック中の場合、新規追加ダイアログは自動表示されないこと', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/memos?action=create',
        routes: [
          GoRoute(
            path: '/memos',
            builder: (context, state) =>
                MemoScreen(action: state.uri.queryParameters['action']),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test_user_id'),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            loggerProvider.overrideWithValue(mockTalker),
            isAppUnlockedProvider.overrideWithValue(false),
          ],
          child: MaterialApp.router(
            localizationsDelegates: [
              MockLocalizationsDelegate(mockL10n),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボトムシート内の「保存」ボタンは表示されていないことを確認
      check(find.text('保存')).findsNothing();
    });

    testWidgets('FilterChip によるカテゴリ絞り込みおよび未同期絞り込みが動作すること', (tester) async {
      final now = DateTime(2026, 10, 25);
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: '仕事のメモ',
          content: '仕事内容',
          createdAt: now,
          updatedAt: now,
          category: MemoCategory.work,
          isSynced: true,
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: '個人のメモ',
          content: '個人内容',
          createdAt: now,
          updatedAt: now,
          category: MemoCategory.personal,
        ),
      ];

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));
      when(
        () => mockMemoRepository.watchFilteredMemos(
          any(),
          query: any(named: 'query'),
          category: any(named: 'category'),
          unsyncedOnly: any(named: 'unsyncedOnly'),
        ),
      ).thenAnswer((invocation) {
        final category = invocation.namedArguments[#category] as MemoCategory?;
        final unsyncedOnly = invocation.namedArguments[#unsyncedOnly] as bool?;
        var result = memoList;
        if (category != null) {
          result = result.where((m) => m.category == category).toList();
        }
        if (unsyncedOnly == true) {
          result = result.where((m) => !m.isSynced).toList();
        }
        return Stream.value(result);
      });

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 初期状態（全件）
      check(find.text('仕事のメモ')).findsOne();
      check(find.text('個人のメモ')).findsOne();

      // 「仕事」FilterChipをタップ
      await tester.tap(find.widgetWithText(FilterChip, '仕事'));
      await tester.pumpAndSettle();

      check(find.text('仕事のメモ')).findsOne();
      check(find.text('個人のメモ')).findsNothing();

      // 「すべて」FilterChipをタップしてリセット
      await tester.tap(find.widgetWithText(FilterChip, 'すべて'));
      await tester.pumpAndSettle();

      check(find.text('仕事のメモ')).findsOne();
      check(find.text('個人のメモ')).findsOne();

      // 「未同期のみ」FilterChipをタップ
      await tester.tap(find.widgetWithText(FilterChip, '未同期のみ'));
      await tester.pumpAndSettle();

      check(find.text('仕事のメモ')).findsNothing();
      check(find.text('個人のメモ')).findsOne();
    });

    testWidgets('検索条件に一致するメモが0件のとき「条件をクリア」ボタンが表示され、タップでクリアされること', (
      tester,
    ) async {
      when(() => mockMemoRepository.watchAllMemos(any())).thenAnswer(
        (_) => Stream.value([
          MemoModel(
            id: '1',
            userId: 'test_user_id',
            title: '既存メモ',
            content: '内容',
            createdAt: DateTime(2026, 10, 25),
            updatedAt: DateTime(2026, 10, 25),
          ),
        ]),
      );
      when(
        () => mockMemoRepository.watchFilteredMemos(
          any(),
          query: any(named: 'query'),
          category: any(named: 'category'),
          unsyncedOnly: any(named: 'unsyncedOnly'),
        ),
      ).thenAnswer((_) => Stream.value([]));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 存在しないキーワードで検索
      await tester.enterText(find.byType(TextField).first, '存在しないキーワード');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 0件メッセージと「条件をクリア」ボタンが表示される
      check(find.text('一致するメモがありません')).findsOne();
      check(find.text('条件をクリア')).findsOne();

      // 「条件をクリア」ボタンをタップ
      await tester.tap(find.text('条件をクリア'));
      await tester.pumpAndSettle();

      // 既存メモが再表示される
      check(find.text('既存メモ')).findsOne();

      // 【再入力直後のクリア検証】0件状態で再入力し、400ms待たずにクリアボタンを押しても遅延発火しないこと
      await tester.enterText(find.byType(TextField).first, '存在しないキーワード');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 0件状態で新しい文字を入力
      await tester.enterText(find.byType(TextField).first, '再入力キーワード');
      await tester.pump();
      // 400ms待たずに「条件をクリア」をタップ
      await tester.tap(find.text('条件をクリア'));
      await tester.pumpAndSettle();

      // 400ms以上経過しても保留中だった「再入力キーワード」で上書きされず全件表示が維持されること
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      check(find.text('既存メモ')).findsOne();
    });

    testWidgets('カテゴリ選択中に検索語を入力し、400ms以内に「すべて」チップを押した場合に保留中検索が取り消されること', (
      tester,
    ) async {
      when(() => mockMemoRepository.watchAllMemos(any())).thenAnswer(
        (_) => Stream.value([
          MemoModel(
            id: '1',
            userId: 'test_user_id',
            title: '仕事のメモ',
            content: '内容1',
            category: MemoCategory.work,
            createdAt: DateTime(2026, 10, 25),
            updatedAt: DateTime(2026, 10, 25),
          ),
          MemoModel(
            id: '2',
            userId: 'test_user_id',
            title: 'アイデアのメモ',
            content: '内容2',
            category: MemoCategory.idea,
            createdAt: DateTime(2026, 10, 25),
            updatedAt: DateTime(2026, 10, 25),
          ),
        ]),
      );
      when(
        () => mockMemoRepository.watchFilteredMemos(
          any(),
          query: any(named: 'query'),
          category: any(named: 'category'),
          unsyncedOnly: any(named: 'unsyncedOnly'),
        ),
      ).thenAnswer((_) => Stream.value([]));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 1. 「仕事」チップをタップしてカテゴリを絞り込み
      await tester.tap(find.widgetWithText(FilterChip, '仕事'));
      await tester.pumpAndSettle();

      // 2. 検索バーに文字を入力（400ms待機中）
      await tester.enterText(find.byType(TextField).first, '未適用の検索語');
      await tester.pump();

      // 3. 400ms待たずに「すべて」チップをタップして全解除
      await tester.tap(find.widgetWithText(FilterChip, 'すべて'));
      await tester.pumpAndSettle();

      // 4. 検索バーの文字がクリアされていること
      check(find.text('未適用の検索語')).findsNothing();

      // 5. 500ms経過しても検索が遅延発火せず、全件表示が維持されること
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      check(find.text('仕事のメモ')).findsOne();
      check(find.text('アイデアのメモ')).findsOne();
    });

    testWidgets('新規メモ追加ダイアログでカテゴリを選択して保存できること', (tester) async {
      when(
        () => mockMemoRepository.addMemo(
          any(),
          any(),
          any(),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // FABをタップしてボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // タイトルと内容を入力
      await tester.enterText(find.widgetWithText(TextField, 'タイトル'), 'アイデアメモ');
      await tester.enterText(find.widgetWithText(TextField, '内容'), '閃いたアイデア');

      // 「アイデア」カテゴリを選択
      await tester.tap(find.widgetWithText(ChoiceChip, 'アイデア'));
      await tester.pumpAndSettle();

      // 「保存」ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // addMemo が MemoCategory.idea を伴って呼ばれたことを確認
      verify(
        () => mockMemoRepository.addMemo(
          'アイデアメモ',
          '閃いたアイデア',
          'test_user_id',
          category: MemoCategory.idea,
        ),
      ).called(1);
    });
  });
}
