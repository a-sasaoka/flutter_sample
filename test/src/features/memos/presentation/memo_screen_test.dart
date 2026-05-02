import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
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
  });

  /// テスト環境のセットアップヘルパー
  Future<void> setupWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // リポジトリをモックに差し替え（これでNotifier側でもモックが使われる）
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            _MockLocalizationsDelegate(mockL10n),
          ],
          home: const MemoScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  group('MemoScreen', () {
    testWidgets('ローディング状態が正しく表示されること', (tester) async {
      // Completerを使って完了しないFutureを返し、ローディング状態を再現
      final completer = Completer<List<MemoModel>>();
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) => completer.future);

      await setupWidget(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('エラー状態が正しく表示されること', (tester) async {
      // エラーを投げるように設定
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) => Future.error(Exception('Test Error')));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('データが空の場合、「メモがありません」と表示されること', (tester) async {
      // 空のリストを返すように設定
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('メモがありません'), findsOneWidget);
    });

    testWidgets('データが存在する場合、リストとして表示されること', (tester) async {
      // 取得されるデータのスタブ
      final memoList = [
        MemoModel(
          id: '1',
          title: 'テストタイトル1',
          content: 'テスト内容1',
          createdAt: DateTime(2026, 5),
          updatedAt: DateTime(2026, 5),
        ),
        MemoModel(
          id: '2',
          title: 'テストタイトル2',
          content: 'テスト内容2',
          createdAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 2),
        ),
      ];
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => memoList);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 各要素が表示されているか検証
      expect(find.text('テストタイトル1'), findsOneWidget);
      expect(find.text('テスト内容1'), findsOneWidget);
      expect(find.text('5/1'), findsOneWidget);

      expect(find.text('テストタイトル2'), findsOneWidget);
      expect(find.text('テスト内容2'), findsOneWidget);
      expect(find.text('5/2'), findsOneWidget);
    });

    testWidgets('新しいメモを入力して送信ボタンを押すと、追加処理が呼ばれ入力欄がクリアされること', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);
      // addMemoが呼ばれた時は何もせずに完了するように設定
      when(
        () => mockMemoRepository.addMemo(any(), any()),
      ).thenAnswer((_) async {});

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // タイトルと内容のTextFieldを取得して入力
      final titleField = find.widgetWithText(TextField, 'タイトル');
      final contentField = find.widgetWithText(TextField, '内容');

      await tester.enterText(titleField, '新しいタイトル');
      await tester.enterText(contentField, '新しい内容');

      // 送信ボタンをタップ
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // addMemoが期待された引数で呼ばれたことを検証
      verify(() => mockMemoRepository.addMemo('新しいタイトル', '新しい内容')).called(1);

      // 送信後、TextFieldがクリアされていることを検証
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        isEmpty,
      );
    });

    testWidgets('タイトルが空の場合、送信ボタンを押しても処理が行われないこと', (tester) async {
      when(() => mockMemoRepository.getAllMemos()).thenAnswer((_) async => []);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      // 内容だけ入力
      final contentField = find.widgetWithText(TextField, '内容');
      await tester.enterText(contentField, '新しい内容');

      // 送信ボタンをタップ
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // addMemoが呼ばれないことを検証
      verifyNever(() => mockMemoRepository.addMemo(any(), any()));
    });
  });
}
