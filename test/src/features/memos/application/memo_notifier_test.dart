import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
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
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      // デフォルトの振る舞い
      when(
        () => mockMemoRepository.fetchAndMergeRemoteMemos(),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      container.dispose();
    });

    test('build() は repository.watchAllMemos() の結果を返すこと', () async {
      final mockMemos = [
        MemoModel(
          id: '1',
          title: 'テストタイトル',
          content: 'テストコンテンツ',
          createdAt: DateTime(2026, 5),
          updatedAt: DateTime(2026, 5),
        ),
      ];

      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => Stream.value(mockMemos));

      final subscription = container.listen(memoProvider, (_, _) {});

      final memos = await container.read(memoProvider.future);

      check(memos).deepEquals(mockMemos);
      verify(() => mockMemoRepository.watchAllMemos()).called(1);

      subscription.close();
    });

    test('addMemo は repository.addMemo() を呼び出すこと', () async {
      final controller = StreamController<List<MemoModel>>();
      addTearDown(controller.close);

      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockMemoRepository.addMemo(any(), any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      controller.add([]);

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).addMemo('タイトル', '内容');

      verify(() => mockMemoRepository.addMemo('タイトル', '内容')).called(1);

      subscription.close();
    });

    test('deleteMemo は repository.deleteMemo() を呼び出すこと', () async {
      final controller = StreamController<List<MemoModel>>();
      addTearDown(controller.close);

      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockMemoRepository.deleteMemo(any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      controller.add([]);

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).deleteMemo('id1');

      verify(() => mockMemoRepository.deleteMemo('id1')).called(1);

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
              memoRepositoryProvider.overrideWithValue(mockMemoRepository),
              isOnlineProvider.overrideWithValue(true),
            ],
          );
          addTearDown(onlineContainer.dispose);

          when(
            () => mockMemoRepository.watchAllMemos(),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(),
          ).thenAnswer((_) async {});

          final subscription = onlineContainer.listen(memoProvider, (_, _) {});
          controller.add([]);
          await onlineContainer.read(memoProvider.future);

          verify(() => mockMemoRepository.fetchAndMergeRemoteMemos()).called(1);
          subscription.close();
        },
      );

      test(
        'build はオンライン時かつ同期処理でエラーが発生した場合にログを出力し、状態は正常に完了すること',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          final talker = Talker();

          final onlineContainer = ProviderContainer(
            overrides: [
              memoRepositoryProvider.overrideWithValue(mockMemoRepository),
              isOnlineProvider.overrideWithValue(true),
              loggerProvider.overrideWithValue(talker),
            ],
          );
          addTearDown(onlineContainer.dispose);

          final exception = Exception('Sync error');

          when(
            () => mockMemoRepository.watchAllMemos(),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(),
          ).thenThrow(exception);

          final subscription = onlineContainer.listen(memoProvider, (_, _) {});
          controller.add([]);
          await onlineContainer.read(memoProvider.future);

          final errorLogs = talker.history.where(
            (log) => log.message == 'バックグラウンド同期中にエラーが発生しました',
          );
          check(errorLogs.length).equals(1);

          subscription.close();
        },
      );

      test(
        'build はオフライン時は repository.fetchAndMergeRemoteMemos() を呼び出さないこと',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          when(
            () => mockMemoRepository.watchAllMemos(),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(),
          ).thenAnswer((_) async {});

          final subscription = container.listen(memoProvider, (_, _) {});
          controller.add([]);
          await container.read(memoProvider.future);

          verifyNever(() => mockMemoRepository.fetchAndMergeRemoteMemos());
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
              memoRepositoryProvider.overrideWithValue(mockMemoRepository),
              isOnlineProvider.overrideWithValue(true),
            ],
          );
          addTearDown(onlineContainer.dispose);

          when(
            () => mockMemoRepository.watchAllMemos(),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(),
          ).thenAnswer((_) async {});

          final subscription = onlineContainer.listen(memoProvider, (_, _) {});
          controller.add([]);
          await onlineContainer.read(memoProvider.future);

          // 初期化時の同期呼び出し履歴をクリアし、sync() 自体の呼び出しのみをカウントできるようにする
          clearInteractions(mockMemoRepository);

          await onlineContainer.read(memoProvider.notifier).sync();

          verify(() => mockMemoRepository.fetchAndMergeRemoteMemos()).called(1);
          subscription.close();
        },
      );

      test(
        'sync はオフライン時は repository.fetchAndMergeRemoteMemos() を呼び出さないこと',
        () async {
          final controller = StreamController<List<MemoModel>>();
          addTearDown(controller.close);

          when(
            () => mockMemoRepository.watchAllMemos(),
          ).thenAnswer((_) => controller.stream);
          when(
            () => mockMemoRepository.fetchAndMergeRemoteMemos(),
          ).thenAnswer((_) async {});

          final subscription = container.listen(memoProvider, (_, _) {});
          controller.add([]);
          await container.read(memoProvider.future);
          clearInteractions(mockMemoRepository);

          await container.read(memoProvider.notifier).sync();

          verifyNever(() => mockMemoRepository.fetchAndMergeRemoteMemos());
          subscription.close();
        },
      );
    });

    test('repository.watchAllMemos() でエラーが発生した場合、状態にエラーが保持されること', () async {
      final exception = Exception('読み込み失敗');

      when(
        () => mockMemoRepository.watchAllMemos(),
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
          title: 'Apple',
          content: 'This is red apple.',
          createdAt: DateTime(2026, 5, 10),
          updatedAt: DateTime(2026, 5, 20),
        ),
        MemoModel(
          id: '2',
          title: 'Banana',
          content: 'Yellow banana juice.',
          createdAt: DateTime(2026, 5, 15),
          updatedAt: DateTime(2026, 5, 18),
        ),
        MemoModel(
          id: '3',
          title: 'Orange juice',
          content: 'Sweet orange.',
          createdAt: DateTime(2026, 5, 5),
          updatedAt: DateTime(2026, 5, 25),
        ),
      ];

      setUp(() {
        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => Stream.value(mockMemos));
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
        final sortSub = container.listen(
          memoSortOrderStateProvider,
          (_, _) {},
        );
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
}
