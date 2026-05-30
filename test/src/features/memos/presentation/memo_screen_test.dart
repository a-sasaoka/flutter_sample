import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
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

      // ボトムシートが表示されていることを確認
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.widgetWithText(TextField, 'タイトル'), '新タイトル');
      await tester.enterText(find.widgetWithText(TextField, '内容'), '新内容');

      // 保存ボタンをタップ
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      verify(() => mockMemoRepository.addMemo('新タイトル', '新内容')).called(1);
      // ボトムシートが閉じていることを確認
      expect(find.byType(TextField), findsNothing);
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
  });
}
