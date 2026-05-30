import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_list_shimmer.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---

class MockMemoRepository extends Mock implements MemoRepository {}

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
  late MockMemoRepository mockMemoRepository;
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockMemoRepository = MockMemoRepository();
    mockL10n = MockAppLocalizations();

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
  });

  /// テスト環境のセットアップヘルパー
  Future<void> setupWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            _MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MemoScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  group('MemoScreen', () {
    testWidgets('ローディング状態が正しく表示されること', (tester) async {
      final completer = Completer<List<MemoModel>>();
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) => completer.future);

      await setupWidget(tester);

      expect(find.byType(MemoListShimmer), findsOneWidget);
    });

    testWidgets('エラー状態が正しく表示されること', (tester) async {
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) => Future.error(Exception('Test Error')));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('データが空の場合、空の状態が表示されること', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('メモがありません'), findsOneWidget);
      expect(find.byIcon(Icons.note_alt_outlined), findsOneWidget);
    });

    testWidgets('データが存在する場合、カードリストとして表示されること', (tester) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final memoList = [
        MemoModel(
          id: '1',
          title: 'タイトル1',
          content: '内容1',
          createdAt: now,
          updatedAt: now,
          isSynced: true,
        ),
      ];
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => memoList);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('タイトル1'), findsOneWidget);
      expect(find.text('内容1'), findsOneWidget);
      expect(find.text('同期済み'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('FABを押すとボトムシートが開き、メモを追加できること', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);
      when(
        () => mockMemoRepository.addMemo(any(), any()),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // FABをタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ボトムシートが表示されていることを確認（検索バー + タイトル + 内容の3つ）
      expect(find.byType(TextField), findsNWidgets(3));

      await tester.enterText(find.widgetWithText(TextField, 'タイトル'), '新タイトル');
      await tester.enterText(find.widgetWithText(TextField, '内容'), '新内容');

      // 保存ボタンをタップ
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      verify(() => mockMemoRepository.addMemo('新タイトル', '新内容')).called(1);
      // ボトムシートが閉じていることを確認（検索バーだけが残っている）
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('削除ボタンを押すとダイアログが表示され、キャンセルすると何も起きないこと', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        title: '消さないメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => [memo]);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // 「閉じる」ボタンをタップしてキャンセル
      await tester.tap(find.widgetWithText(TextButton, '閉じる'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockMemoRepository.deleteMemo(any()));
    });

    testWidgets('削除ボタンを押すとダイアログが表示され、実行すると削除処理が呼ばれること', (tester) async {
      final now = DateTime.now();
      final memo = MemoModel(
        id: '1',
        title: '消すメモ',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => [memo]);
      when(() => mockMemoRepository.deleteMemo(any())).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 削除アイコンをタップ
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // 「削除」ボタンをタップ
      await tester.tap(find.widgetWithText(TextButton, '削除'));
      await tester.pumpAndSettle();

      verify(() => mockMemoRepository.deleteMemo('1')).called(1);
    });

    testWidgets('同期ボタンを押すと同期処理が呼ばれること', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);
      when(
        () => mockMemoRepository.syncUnsentMemos(),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      verify(() => mockMemoRepository.syncUnsentMemos()).called(1);
    });

    testWidgets('引っ張って更新（Pull to Refresh）が動作すること', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // リストを下に引っ張る
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump(); // インジケータ表示開始
      await tester.pump(const Duration(seconds: 1)); // 完了待ち
      await tester.pumpAndSettle();

      // リロードのために getAllMemos が再度呼ばれることを確認
      verify(() => mockMemoRepository.getAllMemos()).called(2);
    });

    testWidgets('検索キーワードを入力した際、部分一致するメモだけが表示されること（インクリメンタルサーチ）', (
      tester,
    ) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final memoList = [
        MemoModel(
          id: '1',
          title: 'りんごのメモ',
          content: '赤くて甘い果物',
          createdAt: now,
          updatedAt: now,
        ),
        MemoModel(
          id: '2',
          title: 'バナナのメモ',
          content: '黄色くて長い果物',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => memoList);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 初期状態では両方表示されている
      expect(find.text('りんごのメモ'), findsOneWidget);
      expect(find.text('バナナのメモ'), findsOneWidget);

      // 検索バーに「りんご」を入力
      await tester.enterText(find.byType(TextField).first, 'りんご');
      await tester.pumpAndSettle();

      // 「りんご」のみ表示され、「バナナ」は非表示になる
      expect(find.text('りんごのメモ'), findsOneWidget);
      expect(find.text('バナナのメモ'), findsNothing);

      // クリアボタンをタップして検索をリセット
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 再び両方表示される
      expect(find.text('りんごのメモ'), findsOneWidget);
      expect(find.text('バナナのメモ'), findsOneWidget);
    });

    testWidgets('ソート順を切り替えた際、指定したルールに従ってリストが並び替わること', (tester) async {
      final t1 = DateTime(2026, 5, 10, 10);
      final t2 = DateTime(2026, 5, 10, 11);
      final memoList = [
        MemoModel(
          id: '1',
          title: 'B_Memo',
          content: 'content B',
          createdAt: t1,
          updatedAt: t2,
        ),
        MemoModel(
          id: '2',
          title: 'A_Memo',
          content: 'content A',
          createdAt: t2,
          updatedAt: t1,
        ),
      ];
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => memoList);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // デフォルトは「作成日時：新しい順」(A_Memoの方がt2で新しいので上に来るはず)
      var posA = tester.getTopLeft(find.text('A_Memo')).dy;
      var posB = tester.getTopLeft(find.text('B_Memo')).dy;
      expect(posA < posB, isTrue); // A_Memo の方が Y 座標が小さく、上にある

      // ソートボタン（PopupMenuButton）をタップ
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // 「作成日時：古い順」を選択
      await tester.tap(find.text('作成：古い順'));
      await tester.pumpAndSettle();

      // B_Memo (t1) の方が古いので上に来るはず
      posA = tester.getTopLeft(find.text('A_Memo')).dy;
      posB = tester.getTopLeft(find.text('B_Memo')).dy;
      expect(posB < posA, isTrue); // B_Memo の方が上にある
    });

    testWidgets('画面外タップでキーボードが閉じること(一覧画面および追加ボトムシート)', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);
      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 1. 一覧画面でのテスト: 検索窓をタップしてフォーカスを当てる
      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      var context = tester.element(searchField);
      expect(FocusScope.of(context).hasFocus, isTrue);

      // 2. AppBar(画面外)をタップしてフォーカスが外れるか確認
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();
      expect(FocusScope.of(context).hasFocus, isFalse);

      // 3. 追加ボトムシートでのテスト: FABをタップしてボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ボトムシート内の最初の入力欄(タイトルTextField)
      final titleField = find.widgetWithText(TextField, 'タイトル');
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      context = tester.element(titleField);
      expect(FocusScope.of(context).hasFocus, isTrue);

      // 4. ボトムシート内の余白部分(GestureDetector)をタップしてフォーカスが外れるか確認
      // GestureDetectorを特定するためにボトムシートの要素をタップします
      await tester.tap(find.text('メモを追加').last);
      await tester.pumpAndSettle();
      expect(FocusScope.of(context).hasFocus, isFalse);
    });

    testWidgets('外部から検索クエリが変更された場合に入力欄の文字が同期して更新されること', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);

      // Riverpodのコンテナに直接アクセスして状態を操作できるようにするため、
      // setupWidget ではなくここで個別にProviderScopeを準備します。
      final container = ProviderContainer(
        overrides: [
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
        ],
      );
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
            home: const MemoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 最初は入力欄は空
      final searchField = find.byType(TextField).first;
      expect(tester.widget<TextField>(searchField).controller?.text, '');

      // 外部(プロバイダー)から検索キーワードを「外部変更キーワード」に変更する
      container.read(memoSearchQueryProvider.notifier).setQuery('外部変更キーワード');
      await tester.pumpAndSettle();

      // 入力欄の文字が「外部変更キーワード」に自動で切り替わっていることを確認
      expect(
        tester.widget<TextField>(searchField).controller?.text,
        '外部変更キーワード',
      );

      container.dispose();
    });
  });
}
