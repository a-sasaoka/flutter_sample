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

        sortSub.close();
        memoSub.close();
      });
    });
  });

  group('MemoFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態が正しく設定されていること', () {
      final state = container.read(memoFilterProvider);
      check(state.query).equals('');
      check(state.category).isNull();
      check(state.unsyncedOnly).equals(false);
      check(state.sortOrder).equals(MemoSortOrder.createdAtDesc);
      check(state.hasActiveFilter).equals(false);
    });

    test('setQuery で検索クエリが更新され、hasActiveFilter が正しく判定されること', () {
      container.read(memoFilterProvider.notifier).setQuery('flutter');
      check(container.read(memoFilterProvider).query).equals('flutter');
      check(container.read(memoFilterProvider).hasActiveFilter).equals(true);

      container.read(memoFilterProvider.notifier).setQuery('');
      check(container.read(memoFilterProvider).query).equals('');
      check(container.read(memoFilterProvider).hasActiveFilter).equals(false);
    });

    test('toggleCategory と setCategory が正しく動作すること', () {
      container
          .read(memoFilterProvider.notifier)
          .toggleCategory(MemoCategory.work);
      check(
        container.read(memoFilterProvider).category,
      ).equals(MemoCategory.work);
      check(container.read(memoFilterProvider).hasActiveFilter).equals(true);

      // 同じカテゴリを再度トグルすると選択解除（null）になること
      container
          .read(memoFilterProvider.notifier)
          .toggleCategory(MemoCategory.work);
      check(container.read(memoFilterProvider).category).isNull();
      check(container.read(memoFilterProvider).hasActiveFilter).equals(false);

      // setCategory で明示的に設定
      container
          .read(memoFilterProvider.notifier)
          .setCategory(MemoCategory.idea);
      check(
        container.read(memoFilterProvider).category,
      ).equals(MemoCategory.idea);
    });

    test('toggleUnsyncedOnly と setUnsyncedOnly が正しく動作すること', () {
      container.read(memoFilterProvider.notifier).toggleUnsyncedOnly();
      check(container.read(memoFilterProvider).unsyncedOnly).equals(true);
      check(container.read(memoFilterProvider).hasActiveFilter).equals(true);

      container.read(memoFilterProvider.notifier).toggleUnsyncedOnly();
      check(container.read(memoFilterProvider).unsyncedOnly).equals(false);
      check(container.read(memoFilterProvider).hasActiveFilter).equals(false);

      // setUnsyncedOnly で明示的に設定
      container
          .read(memoFilterProvider.notifier)
          .setUnsyncedOnly(unsyncedOnly: true);
      check(container.read(memoFilterProvider).unsyncedOnly).equals(true);
    });

    test('setSortOrder が正しく動作すること', () {
      container
          .read(memoFilterProvider.notifier)
          .setSortOrder(MemoSortOrder.titleAsc);
      check(
        container.read(memoFilterProvider).sortOrder,
      ).equals(MemoSortOrder.titleAsc);
    });

    test('resetFilter で全条件が初期値にリセットされること', () {
      container.read(memoFilterProvider.notifier)
        ..setQuery('test')
        ..setCategory(MemoCategory.work)
        ..setUnsyncedOnly(unsyncedOnly: true)
        ..setSortOrder(MemoSortOrder.titleAsc)
        ..resetFilter();
      final resetState = container.read(memoFilterProvider);
      check(resetState.query).equals('');
      check(resetState.category).isNull();
      check(resetState.unsyncedOnly).equals(false);
      check(resetState.sortOrder).equals(MemoSortOrder.titleAsc);
      check(resetState.hasActiveFilter).equals(false);
    });
  });
}
