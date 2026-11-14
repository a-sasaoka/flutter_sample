// ignore_for_file: prefer_const_constructors, document_ignores
import 'dart:async';

import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/services/app_lock_state_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/empty_state_widget.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
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

class _MockMemoRemoteService extends Mock implements MemoRemoteService {}

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
    when(() => mockL10n.memoSortCustom).thenReturn('カスタム順');
    when(() => mockL10n.memoDeleted).thenReturn('メモを削除しました');
    when(() => mockL10n.memoUndo).thenReturn('元に戻す');
    when(() => mockL10n.retry).thenReturn('再試行');

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
      () => mockMemoRepository.getLocalMemos(any()),
    ).thenAnswer((_) async => []);
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

  /// StatefulShellRoute によるタブ切り替え構成のセットアップヘルパー
  Future<void> setupShellWidget(
    WidgetTester tester, {
    List<dynamic>? overrides,
    List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    Locale? locale,
  }) async {
    final router = GoRouter(
      initialLocation: '/memos',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  navigationShell.goBranch(index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.edit_note),
                    label: 'メモ',
                  ),
                  NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
                ],
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/memos',
                  builder: (context, state) => const MemoScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      const Scaffold(body: Text('ホーム画面')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides:
            (overrides ??
                    [
                      currentUserIdProvider.overrideWithValue('test_user_id'),
                      memoRepositoryProvider.overrideWithValue(
                        mockMemoRepository,
                      ),
                      isOnlineProvider.overrideWithValue(true),
                      loggerProvider.overrideWithValue(mockTalker),
                      isAppUnlockedProvider.overrideWithValue(true),
                    ])
                .cast(),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates:
              localizationsDelegates ??
              [
                MockLocalizationsDelegate(mockL10n),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
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

    testWidgets('メモカードを右から左へ横スワイプすると削除処理が呼ばれ、Undoアクション付きSnackBarが表示されること', (
      tester,
    ) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '消すメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      // 📱 削除・復元に応じて複数の一覧を流せる StreamController を用意
      final streamController = StreamController<List<MemoModel>>();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);

      // 削除処理が呼ばれた際、対象メモが除外された一覧（空リスト）を流す
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add(<MemoModel>[]);
      });

      // 復元処理が呼ばれた際、メモが再追加された一覧を流す
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add([memo]);
      });

      // 初期一覧を流して画面を表示
      streamController.add([memo]);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('消すメモ')).findsOne();

      // 右から左へスワイプ（Dismissible）
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // deleteMemo が呼ばれたことを確認
      verify(
        () => mockMemoRepository.deleteMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);

      // 削除によって対象カードが画面から消失していること（空状態になっていること）
      check(find.text('消すメモ')).findsNothing();
      check(find.byType(EmptyStateWidget)).findsOne();

      // SnackBar が表示されていることを確認
      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 「元に戻す」をタップ
      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      // restoreMemo が呼ばれたことを確認
      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);

      // 復元後の一覧でカードが画面に再表示されること
      check(find.text('消すメモ')).findsOne();
      check(find.byType(Card)).findsOne();
    });

    testWidgets('キーボードフォーカスで削除ボタンを実行すると既存の削除とUndo処理が行われること', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: 'キーボード削除メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final streamController = StreamController<List<MemoModel>>();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add(<MemoModel>[]);
      });
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add([memo]);
      });

      streamController.add([memo]);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('キーボード削除メモ')).findsOne();

      // Tabキーで削除ボタンへフォーカスを移動し、Enterキーで削除を実行
      final deleteIconFinder = find.byIcon(Icons.delete_outline);
      check(deleteIconFinder).findsOne();
      final deleteFocusNode = Focus.of(tester.element(deleteIconFinder));
      for (var i = 0; i < 30 && !deleteFocusNode.hasPrimaryFocus; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      check(deleteFocusNode.hasPrimaryFocus).isTrue();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.deleteMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
      check(find.text('キーボード削除メモ')).findsNothing();
      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 「元に戻す」で復元できること
      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
      check(find.text('キーボード削除メモ')).findsOne();
    });

    testWidgets('Undo操作の復元に失敗した場合、エラー通知と再試行アクションが表示され、再試行で同じメモが復元されること', (
      tester,
    ) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '復元失敗メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final streamController = StreamController<List<MemoModel>>();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add(<MemoModel>[]);
      });

      var restoreCallCount = 0;
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        restoreCallCount++;
        if (restoreCallCount == 1) {
          throw Exception('復元失敗');
        }
        streamController.add([memo]);
      });

      streamController.add([memo]);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('復元失敗メモ')).findsOne();

      // 右から左へスワイプ（Dismissible）
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 1回目の「元に戻す」タップは失敗する
      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
      verify(
        () => mockTalker.handle(any(), any(), 'メモの復元中にエラーが発生しました'),
      ).called(1);

      // エラーメッセージと再試行アクション付きのSnackBarが表示されること
      check(find.byType(SnackBar)).findsOne();
      check(find.text('エラーが発生しました')).findsOne();
      check(find.text('再試行')).findsOne();
      check(find.text('復元失敗メモ')).findsNothing();

      // 「再試行」をタップして同じメモの復元が成功すること
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
      check(find.text('復元失敗メモ')).findsOne();
      check(find.byType(Card)).findsOne();
      check(find.text('エラーが発生しました')).findsNothing();
    });

    testWidgets('Undo操作の復元失敗前に画面遷移した場合、エラーログのみ記録され再試行SnackBarは表示されないこと', (
      tester,
    ) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '遷移中メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final restoreCompleter = Completer<void>();

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([memo]));
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) => restoreCompleter.future);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      // 復元処理の完了前に別画面へ遷移（MemoScreen を破棄）
      Navigator.of(tester.element(find.byType(MemoScreen))).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('別画面')),
        ),
      );
      await tester.pumpAndSettle();
      check(find.text('別画面')).findsOne();

      // 画面遷移後に復元が失敗
      restoreCompleter.completeError(Exception('復元失敗'));
      await tester.pumpAndSettle();

      // Non-fatalエラーは記録されるが、別画面上に再試行SnackBarは表示されないこと
      verify(
        () => mockTalker.handle(any(), any(), 'メモの復元中にエラーが発生しました'),
      ).called(1);
      check(find.byType(SnackBar)).findsNothing();
      check(find.text('エラーが発生しました')).findsNothing();
      check(find.text('再試行')).findsNothing();
    });

    testWidgets('スワイプ削除に失敗した場合、エラー通知が表示されカードが維持されること', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '削除失敗メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([memo]));
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenThrow(Exception('削除エラー'));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('削除失敗メモ')).findsOne();

      // 右から左へスワイプ（Dismissible）
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // エラー通知が表示されること
      check(find.byType(SnackBar)).findsOne();
      check(find.text('エラーが発生しました')).findsOne();

      // カードが削除されず画面上に残っていること（再操作可能）
      check(find.text('削除失敗メモ')).findsOne();
      check(find.byType(Card)).findsOne();
    });

    testWidgets('最後のメモをスワイプ削除時、遅延する削除処理とストリーム更新でカードが破棄されてもUndoが表示されること', (
      tester,
    ) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '最後のメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final streamController = StreamController<List<MemoModel>>();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);

      final deleteCompleter = Completer<void>();
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) {
        // DB更新によりストリームから空リストが流れる（カードが破棄される）
        streamController.add(<MemoModel>[]);
        // ローカル削除処理の完了に時間がかかっている状態をシミュレート
        return deleteCompleter.future;
      });
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {});

      // 初期データを流す
      streamController.add([memo]);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('最後のメモ')).findsOne();

      // スワイプ削除を実行
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      // スワイプ消去アニメーションを完了させて confirmDismiss を呼び出す
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      verify(
        () => mockMemoRepository.deleteMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);

      // カードが破棄され、空状態（EmptyStateWidget）が表示されていること
      check(find.text('最後のメモ')).findsNothing();
      check(find.byType(EmptyStateWidget)).findsOne();

      // まだローカル削除処理が完了していないため、Undo通知は表示されていないこと
      check(find.text('メモを削除しました')).findsNothing();

      // 削除処理が完了
      deleteCompleter.complete();
      await tester.pumpAndSettle();

      // カード破棄後でも Undo SnackBar が表示されていること
      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 「元に戻す」をタップして復元処理が呼ばれること
      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
    });

    testWidgets('削除処理の完了前に画面遷移した場合、Undo通知が表示されないこと', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '削除中メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([memo]));

      final deleteCompleter = Completer<void>();
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) => deleteCompleter.future);

      // 同一 MaterialApp 内で画面遷移をシミュレートする ValueNotifier
      final screenNotifier = ValueNotifier<Widget>(const MemoScreen());
      addTearDown(screenNotifier.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test_user_id'),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(true),
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
            home: ValueListenableBuilder<Widget>(
              valueListenable: screenNotifier,
              builder: (_, currentScreen, _) => currentScreen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('削除中メモ')).findsOne();

      // スワイプ削除を開始
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      verify(
        () => mockMemoRepository.deleteMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);

      // 削除処理の完了前に画面遷移（MemoScreenがアンマウントされ、別画面に切り替わる）
      screenNotifier.value = const Scaffold(body: Text('別画面'));
      await tester.pumpAndSettle();

      check(find.text('別画面')).findsOne();
      check(find.text('削除中メモ')).findsNothing();

      // 削除処理が完了
      deleteCompleter.complete();
      await tester.pumpAndSettle();

      // 別画面で Undo 通知が表示されないこと
      check(find.text('メモを削除しました')).findsNothing();
      check(find.text('元に戻す')).findsNothing();
    });

    testWidgets('削除処理の待機中にStatefulShellRouteでタブを切り替えた場合、Undo通知が表示されないこと', (
      tester,
    ) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '削除中メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value([memo]));

      final deleteCompleter = Completer<void>();
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) => deleteCompleter.future);

      // StatefulShellRoute を使った実際のタブ切り替え構成
      await setupShellWidget(tester);
      await tester.pumpAndSettle();

      check(find.text('削除中メモ')).findsOne();
      check(find.byType(MemoScreen)).findsOne();

      // スワイプ削除を開始
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      verify(
        () => mockMemoRepository.deleteMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);

      // 削除処理の完了前に「ホーム」タブをタップして切り替える
      // （StatefulShellRoute により MemoScreen はアンマウントされずに裏で保持される）
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();

      check(find.text('ホーム画面')).findsOne();

      // 削除処理が完了
      deleteCompleter.complete();
      await tester.pumpAndSettle();

      // ホーム画面で Undo 通知が表示されないこと
      check(find.text('メモを削除しました')).findsNothing();
      check(find.text('元に戻す')).findsNothing();
    });

    testWidgets('Undo通知表示中にタブ切り替えすると別タブでは閉じられ、メモタブ復帰で再表示・復元できること', (
      tester,
    ) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '削除対象メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final streamController = StreamController<List<MemoModel>>.broadcast();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add(<MemoModel>[]);
      });
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add([memo]);
      });

      await setupShellWidget(tester);
      streamController.add([memo]);
      await tester.pumpAndSettle();

      check(find.text('削除対象メモ')).findsOne();

      // スワイプ削除を実行して Undo 通知を表示させる
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 「ホーム」タブへ切り替えると、別タブでは Undo 通知が閉じられること
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();

      check(find.text('ホーム画面')).findsOne();
      check(find.text('メモを削除しました')).findsNothing();
      check(find.text('元に戻す')).findsNothing();

      // 「メモ」タブへ戻ると Undo 通知が再表示され、タップで復元できること
      await tester.tap(find.text('メモ'));
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
      check(find.text('削除対象メモ')).findsOne();
    });

    testWidgets(
      '削除通信中にStatefulShellRouteでタブを切り替えて復帰した場合もUndoを再表示し、削除・復元の順序を保って復元できること',
      (tester) async {
        registerFallbackValue(DateTime(2026));
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        const userId = 'test_user_id';
        final now = DateTime(2026, 4, 1, 10);
        await db.memosDao.insertMemo(
          MemosCompanion.insert(
            id: 'memo-1',
            userId: userId,
            title: '通信中タブ切替メモ',
            content: '本文',
            createdAt: now,
            updatedAt: now,
            isSynced: const Value(true),
          ),
        );

        final mockRemoteService = _MockMemoRemoteService();
        when(mockRemoteService.fetchMemos).thenAnswer((_) async => []);
        final deleteRemoteCompleter = Completer<void>();
        final uploadOrder = <bool>[];
        var currentTime = now;

        when(
          () => mockRemoteService.uploadMemo(
            id: 'memo-1',
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: any(named: 'isDeleted'),
          ),
        ).thenAnswer((invocation) async {
          final isDeleted = invocation.namedArguments[#isDeleted] as bool;
          uploadOrder.add(isDeleted);
          if (isDeleted) {
            await deleteRemoteCompleter.future;
          }
        });

        final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));

        await setupShellWidget(
          tester,
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            memoRemoteServiceProvider.overrideWithValue(mockRemoteService),
            currentUserIdProvider.overrideWithValue(userId),
            isOnlineProvider.overrideWithValue(true),
            isAppUnlockedProvider.overrideWithValue(true),
            loggerProvider.overrideWithValue(talker),
            clockProvider.overrideWithValue(
              () => currentTime = currentTime.add(const Duration(seconds: 1)),
            ),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('ja'),
        );
        await tester.pumpAndSettle();

        check(find.text('通信中タブ切替メモ')).findsOne();

        // 左スワイプで削除（リモート削除通信は未完了のままローカル削除完了）
        await tester.drag(find.text('通信中タブ切替メモ'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        check(deleteRemoteCompleter.isCompleted).isFalse();
        check(uploadOrder).deepEquals([true]);
        check(find.text('メモを削除しました')).findsOne();
        check(find.text('元に戻す')).findsOne();

        // 削除通信の待機中に「ホーム」タブへ切り替え（別タブ上では通知が閉じられる）
        await tester.tap(find.text('ホーム'));
        await tester.pumpAndSettle();

        check(find.text('ホーム画面')).findsOne();
        check(find.text('メモを削除しました')).findsNothing();
        check(find.text('元に戻す')).findsNothing();
        check(deleteRemoteCompleter.isCompleted).isFalse();

        // 「メモ」タブへ戻ると Undo 通知が再表示され、復元を実行できる
        await tester.tap(find.text('メモ'));
        await tester.pumpAndSettle();

        check(find.text('メモを削除しました')).findsOne();
        check(find.text('元に戻す')).findsOne();

        await tester.tap(find.text('元に戻す'));
        await tester.pump();

        // 復元通信は先行する削除通信の完了を待ってから順番に実行される
        check(uploadOrder).deepEquals([true]);

        deleteRemoteCompleter.complete();
        await tester.pumpAndSettle();

        check(uploadOrder).deepEquals([true, false]);
        check(find.text('通信中タブ切替メモ')).findsOne();

        final restoredMemo = await db.memosDao.getMemoById('memo-1', userId);
        check(restoredMemo.isDeleted).isFalse();
        check(restoredMemo.isSynced).isTrue();

        // Drift の StreamQueryStore クローズ用ゼロ秒タイマーをテスト終了前に消化させる
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );

    testWidgets('Undo通知をスワイプで閉じた後にタブを切り替えて復帰しても再表示されないこと', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '閉じられるメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final streamController = StreamController<List<MemoModel>>.broadcast();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add(<MemoModel>[]);
      });

      await setupShellWidget(tester);
      streamController.add([memo]);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // ユーザーが Undo 通知をスワイプで閉じる
      await tester.fling(find.byType(SnackBar), const Offset(0, 200), 1000);
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsNothing();
      check(find.text('元に戻す')).findsNothing();

      // タブを切り替えて戻っても再表示されないこと
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();
      check(find.text('ホーム画面')).findsOne();

      await tester.tap(find.text('メモ'));
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsNothing();
      check(find.text('元に戻す')).findsNothing();
    });

    testWidgets('Undo閉鎖アニメーション完了前にタブを往復しても保持され、メモタブ復帰で復元できること', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        userId: 'test_user_id',
        title: '高速往復メモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final streamController = StreamController<List<MemoModel>>.broadcast();
      addTearDown(streamController.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add(<MemoModel>[]);
      });
      when(
        () => mockMemoRepository.restoreMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {
        streamController.add([memo]);
      });

      await setupShellWidget(tester);
      streamController.add([memo]);
      await tester.pumpAndSettle();

      // スワイプ削除して Undo 通知を表示
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      check(find.text('メモを削除しました')).findsOne();

      // 別タブへ切り替え（閉鎖アニメーション完了前の 50ms 時点で止める）
      await tester.tap(find.text('ホーム'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 閉鎖完了を待たずにメモタブへ戻る（再び 50ms のみ経過）
      await tester.tap(find.text('メモ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 再び別タブへ切り替え、今度は全アニメーション完了まで待機
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();
      check(find.text('ホーム画面')).findsOne();
      check(find.text('メモを削除しました')).findsNothing();
      check(find.text('元に戻す')).findsNothing();

      // メモタブへ戻った際、Undo 通知が失われずに再表示され復元できること
      await tester.tap(find.text('メモ'));
      await tester.pumpAndSettle();

      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();

      verify(
        () => mockMemoRepository.restoreMemo(
          '1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
      ).called(1);
      check(find.text('高速往復メモ')).findsOne();
    });

    testWidgets('リモート削除の完了前でもローカル削除成功時点でUndoでき、画面遷移後も削除・復元の順序が保たれること', (
      tester,
    ) async {
      registerFallbackValue(DateTime(2026));
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      const userId = 'test_user_id';
      final now = DateTime(2026, 4, 1, 10);
      await db.memosDao.insertMemo(
        MemosCompanion.insert(
          id: 'memo-1',
          userId: userId,
          title: 'テストメモ',
          content: '本文',
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(true),
        ),
      );

      final mockRemoteService = _MockMemoRemoteService();
      when(mockRemoteService.fetchMemos).thenAnswer((_) async => []);
      final deleteRemoteCompleter = Completer<void>();
      final uploadOrder = <bool>[];
      var currentTime = now;

      when(
        () => mockRemoteService.uploadMemo(
          id: 'memo-1',
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      ).thenAnswer((invocation) async {
        final isDeleted = invocation.namedArguments[#isDeleted] as bool;
        uploadOrder.add(isDeleted);
        if (isDeleted) {
          await deleteRemoteCompleter.future;
        }
      });

      final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      final screenNotifier = ValueNotifier<Widget>(const MemoScreen());
      addTearDown(screenNotifier.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            memoRemoteServiceProvider.overrideWithValue(mockRemoteService),
            currentUserIdProvider.overrideWithValue(userId),
            isOnlineProvider.overrideWithValue(true),
            isAppUnlockedProvider.overrideWithValue(true),
            loggerProvider.overrideWithValue(talker),
            clockProvider.overrideWithValue(
              () => currentTime = currentTime.add(const Duration(seconds: 1)),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ja'),
            home: ValueListenableBuilder<Widget>(
              valueListenable: screenNotifier,
              builder: (context, child, _) => child,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // メモが表示されていることを確認
      check(find.text('テストメモ')).findsOne();

      // 左スワイプして削除を実行
      await tester.drag(find.text('テストメモ'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // リモート削除通信は完了していないが、ローカル削除成功により即座に Undo 通知が表示される
      check(deleteRemoteCompleter.isCompleted).isFalse();
      check(uploadOrder).deepEquals([true]);
      check(find.text('メモを削除しました')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 通信完了を待つ間に別画面へ遷移しても、復元手段（SnackBarとProvider状態）が保たれる
      screenNotifier.value = const Scaffold(body: Text('別画面'));
      await tester.pumpAndSettle();
      check(find.text('別画面')).findsOne();
      check(find.text('元に戻す')).findsOne();

      // 別画面上で「元に戻す」をタップして復元を実行
      await tester.tap(find.text('元に戻す'));
      await tester.pump();

      // 復元用の通信は削除通信の完了を待ってから順番に送信される
      check(uploadOrder).deepEquals([true]);

      // 先行の削除通信が完了したあと、復元通信が続いて実行される
      deleteRemoteCompleter.complete();
      await tester.pumpAndSettle();

      check(uploadOrder).deepEquals([true, false]);

      final restoredMemo = await db.memosDao.getMemoById('memo-1', userId);
      check(restoredMemo.isDeleted).isFalse();
      check(restoredMemo.isSynced).isTrue();
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

    testWidgets('フィルター未適用状態で検索語を入力し、400ms以内に「すべて」チップを押した場合に保留中検索が取り消されること', (
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

      // 1. カテゴリ等のフィルターが何もない状態で検索バーに文字を入力（400ms待機中）
      await tester.enterText(find.byType(TextField).first, '未適用の検索語');
      await tester.pump();

      // 2. 400ms待たずに「すべて」チップをタップ
      await tester.tap(find.widgetWithText(FilterChip, 'すべて'));
      await tester.pumpAndSettle();

      // 3. 検索バーの文字がクリアされていること
      check(find.text('未適用の検索語')).findsNothing();

      // 4. 500ms経過しても検索が遅延発火せず、全件表示が維持されること
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      check(find.text('仕事のメモ')).findsOne();
      check(find.text('アイデアのメモ')).findsOne();
    });

    testWidgets(
      'カテゴリ選択中に検索語を入力し、400ms以内に同一カテゴリチップを押して個別解除した場合、検索語が保持され検索が発火すること',
      (tester) async {
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
        ).thenAnswer((invocation) {
          final query = invocation.namedArguments[#query] as String? ?? '';
          final category =
              invocation.namedArguments[#category] as MemoCategory?;
          if (query == 'ひらめき' && category == null) {
            return Stream.value([
              MemoModel(
                id: '2',
                userId: 'test_user_id',
                title: 'ひらめきのメモ',
                content: '内容2',
                category: MemoCategory.idea,
                createdAt: DateTime(2026, 10, 25),
                updatedAt: DateTime(2026, 10, 25),
              ),
            ]);
          }
          return Stream.value([]);
        });

        await setupWidget(tester);
        await tester.pumpAndSettle();

        // 1. 「仕事」チップをタップしてカテゴリ絞り込み
        await tester.tap(find.widgetWithText(FilterChip, '仕事'));
        await tester.pumpAndSettle();

        // 2. 検索バーに文字を入力（400ms待機中）
        await tester.enterText(find.byType(TextField).first, 'ひらめき');
        await tester.pump();

        // 3. 400ms待たずに「仕事」チップをもう一度タップしてカテゴリ選択のみ解除
        await tester.tap(find.widgetWithText(FilterChip, '仕事'));
        await tester.pumpAndSettle();

        // 4. 個別解除では検索バーの入力文字が消えずに残っていること
        check(find.text('ひらめき')).findsOne();

        // 5. 400ms経過後にデバウンス検索が実行され、「ひらめきのメモ」のみが表示されること
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        check(find.text('ひらめきのメモ')).findsOne();
        check(find.text('仕事のメモ')).findsNothing();
      },
    );

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

    testWidgets('ドラッグハンドルの表示およびカスタムソート選択テスト', (tester) async {
      final now = DateTime.now();
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'メモ1',
          content: '内容1',
          createdAt: now,
          updatedAt: now,
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'メモ2',
          content: '内容2',
          createdAt: now.add(const Duration(minutes: 1)),
          updatedAt: now.add(const Duration(minutes: 1)),
          sortOrder: 1,
        ),
      ];
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));
      when(
        () => mockMemoRepository.updateSortOrders(any(), any()),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 初期状態（フィルタなし）では ReorderableDragStartListener が2つ存在する
      check(find.byType(ReorderableDragStartListener)).findsExactly(2);

      // onReorderItem が呼ばれた際に reorderMemos が実行されること
      final reorderableListView = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderableListView.onReorderItem!(0, 1);
      await tester.pumpAndSettle();
      verify(() => mockMemoRepository.updateSortOrders(any(), any())).called(1);

      // ソートメニューから「カスタム順」を選択できること
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      check(find.text('カスタム順')).findsOne();
      await tester.tap(find.text('カスタム順'));
      await tester.pumpAndSettle();

      // 検索時に一致するメモを返すようにモックを設定
      when(
        () => mockMemoRepository.watchFilteredMemos(
          any(),
          query: any(named: 'query'),
          category: any(named: 'category'),
          unsyncedOnly: any(named: 'unsyncedOnly'),
        ),
      ).thenAnswer(
        (_) => Stream.value([
          MemoModel(
            id: '1',
            userId: 'test_user_id',
            title: '検索結果メモ',
            content: '内容1',
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      );

      // 検索窓に文字を入力するとフィルタがアクティブになり、
      // 検索結果カードが表示されるが、ドラッグハンドルは無効（ReorderableDragStartListenerが0）になること
      await tester.enterText(find.byType(TextField).first, '検索');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      // 検索結果カードが表示されていること
      check(find.text('検索結果メモ')).findsOne();
      // カードが表示されている状態でも、ドラッグハンドルが存在しないこと
      check(find.byType(ReorderableDragStartListener)).findsNothing();
    });

    testWidgets('並び替え保存に失敗した場合にエラーSnackBarが表示されること', (tester) async {
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'メモ1',
          content: '内容1',
          createdAt: DateTime(2026, 10, 25),
          updatedAt: DateTime(2026, 10, 25),
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'メモ2',
          content: '内容2',
          createdAt: DateTime(2026, 10, 25),
          updatedAt: DateTime(2026, 10, 25),
          sortOrder: 1,
        ),
      ];
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));
      when(
        () => mockMemoRepository.getLocalMemos(any()),
      ).thenAnswer((_) async => memoList);
      when(
        () => mockMemoRepository.updateSortOrders(any(), any()),
      ).thenThrow(Exception('並び替え保存失敗'));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      final reorderableListView = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderableListView.onReorderItem!(0, 1);
      await tester.pumpAndSettle();

      // 保存失敗のエラーSnackBarが表示されること
      check(find.byType(SnackBar)).findsOne();
      check(find.text('エラーが発生しました')).findsOne();
    });

    testWidgets('並び替え保存の待機中にタブを切り替えた場合、失敗してもエラーSnackBarが表示されないこと', (
      tester,
    ) async {
      final memoList = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'メモ1',
          content: '内容1',
          createdAt: DateTime(2026, 10, 25),
          updatedAt: DateTime(2026, 10, 25),
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'メモ2',
          content: '内容2',
          createdAt: DateTime(2026, 10, 25),
          updatedAt: DateTime(2026, 10, 25),
          sortOrder: 1,
        ),
      ];
      final reorderCompleter = Completer<void>();
      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(memoList));
      when(
        () => mockMemoRepository.getLocalMemos(any()),
      ).thenAnswer((_) async => memoList);
      when(
        () => mockMemoRepository.updateSortOrders(any(), any()),
      ).thenAnswer((_) => reorderCompleter.future);

      await setupShellWidget(tester);
      await tester.pumpAndSettle();

      final reorderableListView = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderableListView.onReorderItem!(0, 1);
      await tester.pump();

      // 保存完了前に別タブへ切り替える
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();
      check(find.text('ホーム画面')).findsOne();

      // 別タブ表示中に並び替え保存が失敗
      reorderCompleter.completeError(Exception('並び替え保存失敗'));
      await tester.pumpAndSettle();

      // 別タブ上にエラーSnackBarが表示されないこと
      check(find.byType(SnackBar)).findsNothing();
      check(find.text('エラーが発生しました')).findsNothing();
    });
  });
}
