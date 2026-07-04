import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'memo_screen_test.dart';

void main() {
  group('MemoScreen Golden Tests', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();

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

    Widget buildMemoForGolden({
      required List<MemoModel> memos,
      required ThemeMode themeMode,
    }) {
      // 💡 各シナリオ間でモックの設定（stub）が競合して上書きされるのを防ぐため、
      // シナリオごとに新しく MockMemoRepository をインスタンス化します。
      final repository = MockMemoRepository();

      when(
        // モックの仕様上、クロージャとして渡す必要があるため、unnecessary_lambdas を無視します。
        // ignore: unnecessary_lambdas
        () => repository.fetchAndMergeRemoteMemos(),
      ).thenAnswer((_) async {});

      when(
        // モックの仕様上、クロージャとして渡す必要があるため、unnecessary_lambdas を無視します。
        // ignore: unnecessary_lambdas
        () => repository.watchAllMemos(),
      ).thenAnswer((_) => Stream.value(memos));

      final isDark = themeMode == ThemeMode.dark;

      return ProviderScope(
        overrides: [
          memoRepositoryProvider.overrideWithValue(repository),
          isOnlineProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: isDark
              ? AppTheme.dark().copyWith(
                  textTheme: AppTheme.dark().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                )
              : AppTheme.light().copyWith(
                  textTheme: AppTheme.light().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                ),
          themeMode: themeMode,
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MemoScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'MemoScreen の描画 (ライト/ダーク・空/データあり)',
      fileName: 'memo_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Empty State - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMemoForGolden(
                memos: [],
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty State - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMemoForGolden(
                memos: [],
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With Memos - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMemoForGolden(
                memos: [
                  MemoModel(
                    id: '1',
                    title: '買物リスト',
                    content: '牛乳、卵、りんごを買う。',
                    createdAt: DateTime(2026, 6, 6, 10),
                    updatedAt: DateTime(2026, 6, 6, 10),
                    isSynced: true,
                  ),
                  MemoModel(
                    id: '2',
                    title: 'アイデア',
                    content: 'Flutterのゴールデンテストを導入する。',
                    createdAt: DateTime(2026, 6, 5, 15, 30),
                    updatedAt: DateTime(2026, 6, 5, 15, 30),
                  ),
                ],
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With Memos - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMemoForGolden(
                memos: [
                  MemoModel(
                    id: '1',
                    title: '買物リスト',
                    content: '牛乳、卵、りんごを買う。',
                    createdAt: DateTime(2026, 6, 6, 10),
                    updatedAt: DateTime(2026, 6, 6, 10),
                    isSynced: true,
                  ),
                  MemoModel(
                    id: '2',
                    title: 'アイデア',
                    content: 'Flutterのゴールデンテストを導入する。',
                    createdAt: DateTime(2026, 6, 5, 15, 30),
                    updatedAt: DateTime(2026, 6, 5, 15, 30),
                  ),
                ],
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
