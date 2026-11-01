import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockMemoRepository extends Mock implements MemoRepository {}

void main() {
  group('MemoNotifier', () {
    late MockMemoRepository mockMemoRepository;
    late ProviderContainer container;

    setUp(() {
      mockMemoRepository = MockMemoRepository();
      container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test_user_id'),
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
          isOnlineProvider.overrideWithValue(false),
          loggerProvider.overrideWithValue(Talker()),
        ],
      );
      // デフォルトの振る舞い
      when(
        () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockMemoRepository.watchFilteredMemos(
          any(),
          query: any(named: 'query'),
          category: any(named: 'category'),
          unsyncedOnly: any(named: 'unsyncedOnly'),
        ),
      ).thenAnswer((_) => Stream.value(<MemoModel>[]));
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'build() は未ログイン（userId == null）時に空のリストを返し、watchAllMemosを呼び出さないこと',
      () async {
        final loggedOutContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(null),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
          ],
        );
        addTearDown(loggedOutContainer.dispose);

        final subscription = loggedOutContainer.listen(memoProvider, (_, _) {});
        final memos = await loggedOutContainer.read(memoProvider.future);

        check(memos).isEmpty();
        verifyNever(() => mockMemoRepository.watchAllMemos(any()));
        subscription.close();
      },
    );

    test('build() は repository.watchAllMemos() の結果を返すこと', () async {
      final mockMemos = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'テストタイトル',
          content: 'テストコンテンツ',
          createdAt: DateTime(2026, 5),
          updatedAt: DateTime(2026, 5),
        ),
      ];

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.value(mockMemos));

      final subscription = container.listen(memoProvider, (_, _) {});

      final memos = await container.read(memoProvider.future);

      check(memos).deepEquals(mockMemos);
      verify(() => mockMemoRepository.watchAllMemos('test_user_id')).called(1);

      subscription.close();
    });

    test('addMemo は repository.addMemo() を呼び出すこと', () async {
      final controller = StreamController<List<MemoModel>>();
      addTearDown(controller.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockMemoRepository.addMemo(any(), any(), any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      controller.add([]);

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).addMemo('タイトル', '内容');

      verify(
        () => mockMemoRepository.addMemo('タイトル', '内容', 'test_user_id'),
      ).called(1);

      subscription.close();
    });

    test('deleteMemo は repository.deleteMemo() を呼び出すこと', () async {
      final controller = StreamController<List<MemoModel>>();
      addTearDown(controller.close);

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockMemoRepository.deleteMemo(any(), any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      controller.add([]);

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).deleteMemo('id1');

      verify(
        () => mockMemoRepository.deleteMemo('id1', 'test_user_id'),
      ).called(1);

      subscription.close();
    });

    group('初期化時（build）の同期処理', () {
      test(
        'build はオンライン時に repository.fetchAndMergeRemoteMemos() を呼び出すこと',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          final onlineContainer = ProviderContainer(
            overrides: [
              currentUserIdProvider.overrideWithValue('test_user_id'),
              memoRepositoryProvider.overrideWithValue(mockMemoRepository),
              isOnlineProvider.overrideWithValue(true),
            ],
          );
          addTearDown(onlineContainer.dispose);

          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
          ).thenAnswer((_) async {});

          final subscription = onlineContainer.listen(memoProvider, (_, _) {});
          controller.add([]);
          await onlineContainer.read(memoProvider.future);

          verify(
            () => mockMemoRepository.fetchAndMergeRemoteMemos('test_user_id'),
          ).called(1);
          subscription.close();
        },
      );

      test('build はオンライン時かつ同期処理でエラーが発生した場合にログを出力し、状態は正常に完了すること', () async {
        final controller = StreamController<List<MemoModel>>();
        addTearDown(controller.close);

        final talker = Talker();

        final onlineContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('test_user_id'),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(true),
            loggerProvider.overrideWithValue(talker),
          ],
        );
        addTearDown(onlineContainer.dispose);

        final exception = Exception('Sync error');

        when(
          () => mockMemoRepository.watchAllMemos(any()),
        ).thenAnswer((_) => controller.stream);
        when(
          () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
        ).thenThrow(exception);

        final subscription = onlineContainer.listen(memoProvider, (_, _) {});
        controller.add([]);
        await onlineContainer.read(memoProvider.future);

        final errorLogs = talker.history.where(
          (log) => log.message == 'バックグラウンド同期中にエラーが発生しました',
        );
        check(errorLogs.length).equals(1);

        subscription.close();
      });

      test(
        'build はオフライン時は repository.fetchAndMergeRemoteMemos() を呼び出さないこと',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
          ).thenAnswer((_) async {});

          final subscription = container.listen(memoProvider, (_, _) {});
          controller.add([]);
          await container.read(memoProvider.future);

          verifyNever(() => mockMemoRepository.fetchAndMergeRemoteMemos(any()));
          subscription.close();
        },
      );

      test(
        'build は入力値（searchQueryやsortOrder）が変更されて再構築される際に、追加のリモート同期を呼び出さないこと',
        () async {
          final onlineContainer = ProviderContainer(
            overrides: [
              currentUserIdProvider.overrideWithValue('test_user_id'),
              memoRepositoryProvider.overrideWithValue(mockMemoRepository),
              isOnlineProvider.overrideWithValue(true),
            ],
          );
          addTearDown(onlineContainer.dispose);

          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => Stream.value(<MemoModel>[]));
          when(
            () => mockMemoRepository.watchFilteredMemos(
              any(),
              query: any(named: 'query'),
              category: any(named: 'category'),
              unsyncedOnly: any(named: 'unsyncedOnly'),
            ),
          ).thenAnswer((_) => Stream.value(<MemoModel>[]));
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
          ).thenAnswer((_) async {});

          final subscription = onlineContainer.listen(memoProvider, (_, _) {});
          await onlineContainer.read(memoProvider.future);

          // 初回ビルド時に fetchAndMergeRemoteMemos が1回呼ばれることを検証
          verify(
            () => mockMemoRepository.fetchAndMergeRemoteMemos('test_user_id'),
          ).called(1);
          clearInteractions(mockMemoRepository);

          // searchQueryProviderを更新して再構築をトリガー
          onlineContainer
              .read(memoSearchQueryProvider.notifier)
              .setQuery('search word');
          await onlineContainer.read(memoProvider.future);

          // sortOrderStateProviderを更新して再構築をトリガー
          onlineContainer
              .read(memoSortOrderStateProvider.notifier)
              .setSortOrder(MemoSortOrder.titleAsc);
          await onlineContainer.read(memoProvider.future);

          // 追加の同期呼び出しが行われていないことを検証
          verifyNever(() => mockMemoRepository.fetchAndMergeRemoteMemos(any()));

          subscription.close();
        },
      );
    });

    group('手動同期（sync）の動作', () {
      test(
        'sync はオンライン時に repository.fetchAndMergeRemoteMemos() を呼び出すこと',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          final onlineContainer = ProviderContainer(
            overrides: [
              currentUserIdProvider.overrideWithValue('test_user_id'),
              memoRepositoryProvider.overrideWithValue(mockMemoRepository),
              isOnlineProvider.overrideWithValue(true),
            ],
          );
          addTearDown(onlineContainer.dispose);

          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
          ).thenAnswer((_) async {});

          final subscription = onlineContainer.listen(memoProvider, (_, _) {});
          controller.add([]);
          await onlineContainer.read(memoProvider.future);

          // 初期化時の同期呼び出し履歴をクリアし、sync() 自体の呼び出しのみをカウントできるようにする
          clearInteractions(mockMemoRepository);

          await onlineContainer.read(memoProvider.notifier).sync();

          verify(
            () => mockMemoRepository.fetchAndMergeRemoteMemos('test_user_id'),
          ).called(1);
          subscription.close();
        },
      );

      test(
        'sync はオフライン時は repository.fetchAndMergeRemoteMemos() を呼び出さないこと',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
          ).thenAnswer((_) async {});

          final subscription = container.listen(memoProvider, (_, _) {});
          controller.add([]);
          await container.read(memoProvider.future);
          clearInteractions(mockMemoRepository);

          await container.read(memoProvider.notifier).sync();

          verifyNever(() => mockMemoRepository.fetchAndMergeRemoteMemos(any()));
          subscription.close();
        },
      );
    });

    test('repository.watchAllMemos() でエラーが発生した場合、状態にエラーが保持されること', () async {
      final exception = Exception('読み込み失敗');

      when(
        () => mockMemoRepository.watchAllMemos(any()),
      ).thenAnswer((_) => Stream.error(exception));

      final subscription = container.listen(memoProvider, (_, _) {});

      var count = 0;
      while (!container.read(memoProvider).hasError && count < 10) {
        await Future<void>.delayed(Duration.zero);
        count++;
      }

      final state = container.read(memoProvider);
      check(state.hasError).equals(true);
      check(state.error).equals(exception);

      subscription.close();
    });

    group('検索・ソート機能のテスト', () {
      final mockMemos = [
        MemoModel(
          id: '1',
          userId: 'test_user_id',
          title: 'Apple',
          content: 'This is red apple.',
          createdAt: DateTime(2026, 5, 10),
          updatedAt: DateTime(2026, 5, 20),
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'Banana',
          content: 'Yellow banana juice.',
          createdAt: DateTime(2026, 5, 15),
          updatedAt: DateTime(2026, 5, 18),
        ),
        MemoModel(
          id: '3',
          userId: 'test_user_id',
          title: 'Orange juice',
          content: 'Sweet orange.',
          createdAt: DateTime(2026, 5, 5),
          updatedAt: DateTime(2026, 5, 25),
        ),
      ];

      setUp(() {
        when(
          () => mockMemoRepository.watchAllMemos(any()),
        ).thenAnswer((_) => Stream.value(mockMemos));
        when(
          () => mockMemoRepository.watchFilteredMemos(
            any(),
            query: any(named: 'query'),
            category: any(named: 'category'),
            unsyncedOnly: any(named: 'unsyncedOnly'),
          ),
        ).thenAnswer((invocation) {
          final query = invocation.namedArguments[#query] as String?;
          final category =
              invocation.namedArguments[#category] as MemoCategory?;
          final unsyncedOnly =
              invocation.namedArguments[#unsyncedOnly] as bool?;
          var result = mockMemos;
          if (query != null && query.trim().isNotEmpty) {
            final q = query.trim().toLowerCase();
            result = result
                .where(
                  (m) =>
                      m.title.toLowerCase().contains(q) ||
                      m.content.toLowerCase().contains(q),
                )
                .toList();
          }
          if (category != null) {
            result = result.where((m) => m.category == category).toList();
          }
          if (unsyncedOnly == true) {
            result = result.where((m) => !m.isSynced).toList();
          }
          return Stream.value(result);
        });
      });

      test('検索キーワードによる絞り込みができること', () async {
        final querySub = container.listen(memoSearchQueryProvider, (_, _) {});
        final memoSub = container.listen(memoProvider, (_, _) {});

        var memos = await container.read(memoProvider.future);
        check(memos.length).equals(3);

        container.read(memoSearchQueryProvider.notifier).setQuery(' BANANA ');
        memos = await container.read(memoProvider.future);
        check(memos.length).equals(1);
        check(memos.first.id).equals('2');

        container.read(memoSearchQueryProvider.notifier).setQuery('juice');
        memos = await container.read(memoProvider.future);
        check(memos.length).equals(2);
        check(memos.any((m) => m.id == '2')).equals(true);
        check(memos.any((m) => m.id == '3')).equals(true);

        querySub.close();
        memoSub.close();
      });

      test('ソート順を指定して並び替えができること', () async {
        final sortSub = container.listen(memoSortOrderStateProvider, (_, _) {});
        final memoSub = container.listen(memoProvider, (_, _) {});

        container
            .read(memoSortOrderStateProvider.notifier)
            .setSortOrder(MemoSortOrder.createdAtAsc);
        var memos = await container.read(memoProvider.future);
        check(memos.map((m) => m.id).toList()).deepEquals(['3', '1', '2']);

        container
            .read(memoSortOrderStateProvider.notifier)
            .setSortOrder(MemoSortOrder.updatedAtDesc);
        memos = await container.read(memoProvider.future);
        check(memos.map((m) => m.id).toList()).deepEquals(['3', '1', '2']);

        container
            .read(memoSortOrderStateProvider.notifier)
            .setSortOrder(MemoSortOrder.updatedAtAsc);
        memos = await container.read(memoProvider.future);
        check(memos.map((m) => m.id).toList()).deepEquals(['2', '1', '3']);

        container
            .read(memoSortOrderStateProvider.notifier)
            .setSortOrder(MemoSortOrder.titleAsc);
        memos = await container.read(memoProvider.future);
        check(memos.map((m) => m.id).toList()).deepEquals(['1', '2', '3']);

        container
            .read(memoSortOrderStateProvider.notifier)
            .setSortOrder(MemoSortOrder.titleDesc);
        memos = await container.read(memoProvider.future);
        check(memos.map((m) => m.id).toList()).deepEquals(['3', '2', '1']);

        container
            .read(memoSortOrderStateProvider.notifier)
            .setSortOrder(MemoSortOrder.custom);
        memos = await container.read(memoProvider.future);
        check(memos.map((m) => m.id).toList()).deepEquals(['1', '2', '3']);

        sortSub.close();
        memoSub.close();
      });

      test('reorderMemos: 正常系でOptimistic UI更新されDB一括保存が呼ばれること', () async {
        when(
          () => mockMemoRepository.updateSortOrders(any(), any()),
        ).thenAnswer((_) async {});

        final memoSub = container.listen(memoProvider, (_, _) {});
        await container.read(memoProvider.future);

        // 最初の順序（作成日降順）: 2, 1, 3
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['2', '1', '3']);

        // index 0（'2'）を index 2 の位置へ移動
        await container.read(memoProvider.notifier).reorderMemos(0, 2);

        // Optimistic UIで即時反映: 1, 3, 2
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['1', '3', '2']);

        // ソート順が自動でcustomに切り替わっていること
        check(
          container.read(memoFilterProvider).sortOrder,
        ).equals(MemoSortOrder.custom);

        verify(
          () => mockMemoRepository.updateSortOrders([
            '1',
            '3',
            '2',
          ], 'test_user_id'),
        ).called(1);

        memoSub.close();
      });

      test('reorderMemos: DB更新エラー時に元の順序にロールバックされること', () async {
        when(
          () => mockMemoRepository.updateSortOrders(any(), any()),
        ).thenThrow(Exception('DB Error'));

        final memoSub = container.listen(memoProvider, (_, _) {});
        await container.read(memoProvider.future);

        final initialIds = ['2', '1', '3'];

        // 例外がスローされ、stateがロールバックされることを検証
        await check(
          container.read(memoProvider.notifier).reorderMemos(0, 1),
        ).throws<Exception>();

        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(initialIds);

        memoSub.close();
      });

      test('reorderMemos: フィルタ適用中・同位置移動・未ログイン時は何もしないこと', () async {
        final memoSub = container.listen(memoProvider, (_, _) {});
        await container.read(memoProvider.future);

        // 1. 同一インデックスへの移動
        await container.read(memoProvider.notifier).reorderMemos(1, 1);
        verifyNever(() => mockMemoRepository.updateSortOrders(any(), any()));

        // 2. 検索中（アクティブフィルタあり）
        container.read(memoFilterProvider.notifier).setQuery('search');
        await container.read(memoProvider.notifier).reorderMemos(0, 1);
        verifyNever(() => mockMemoRepository.updateSortOrders(any(), any()));

        // 3. 未ログイン
        final loggedOutContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(null),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
          ],
        );
        addTearDown(loggedOutContainer.dispose);
        await loggedOutContainer.read(memoProvider.notifier).reorderMemos(0, 1);
        verifyNever(() => mockMemoRepository.updateSortOrders(any(), any()));

        memoSub.close();
      });

      test('restoreMemo: ログイン時にリポジトリのrestoreMemoが呼ばれ、未ログイン時は何もしないこと', () async {
        when(
          () => mockMemoRepository.restoreMemo(any(), any()),
        ).thenAnswer((_) async {});

        // ログイン時
        await container.read(memoProvider.notifier).restoreMemo('memo-1');
        verify(
          () => mockMemoRepository.restoreMemo('memo-1', 'test_user_id'),
        ).called(1);

        // 未ログイン時
        final loggedOutContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(null),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
          ],
        );
        addTearDown(loggedOutContainer.dispose);
        await loggedOutContainer
            .read(memoProvider.notifier)
            .restoreMemo('memo-1');
        verifyNever(() => mockMemoRepository.restoreMemo('memo-1', any()));
      });
    });
  });
}
