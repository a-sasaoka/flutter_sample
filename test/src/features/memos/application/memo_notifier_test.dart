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

class _TestUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'user_a';

  String? get userId => state;
  set userId(String? id) => state = id;
}

final _testUserIdProvider = NotifierProvider<_TestUserIdNotifier, String?>(
  _TestUserIdNotifier.new,
);

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
        () => mockMemoRepository.getLocalMemos(any()),
      ).thenAnswer((_) async => <MemoModel>[]);
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
        () => mockMemoRepository.deleteMemo(
          any(),
          any(),
          waitForRemoteSync: any(named: 'waitForRemoteSync'),
        ),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      controller.add([]);

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).deleteMemo('id1');

      verify(
        () => mockMemoRepository.deleteMemo(
          'id1',
          'test_user_id',
          waitForRemoteSync: false,
        ),
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
          sortOrder: 3,
        ),
        MemoModel(
          id: '2',
          userId: 'test_user_id',
          title: 'Banana',
          content: 'Yellow banana juice.',
          createdAt: DateTime(2026, 5, 15),
          updatedAt: DateTime(2026, 5, 18),
          sortOrder: 1,
        ),
        MemoModel(
          id: '3',
          userId: 'test_user_id',
          title: 'Orange juice',
          content: 'Sweet orange.',
          createdAt: DateTime(2026, 5, 5),
          updatedAt: DateTime(2026, 5, 25),
          sortOrder: 2,
        ),
      ];

      setUp(() {
        when(
          () => mockMemoRepository.watchAllMemos(any()),
        ).thenAnswer((_) => Stream.value(mockMemos));
        when(
          () => mockMemoRepository.getLocalMemos(any()),
        ).thenAnswer((_) async => mockMemos);
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
        check(memos.map((m) => m.id).toList()).deepEquals(['2', '3', '1']);

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

      test(
        'reorderMemos: 保存中に重複して並び替えが行われ失敗した場合、最後に保存確認された順序にロールバックされること',
        () async {
          final completer1 = Completer<void>();
          final completer2 = Completer<void>();

          when(
            () => mockMemoRepository.updateSortOrders(any(), any()),
          ).thenAnswer((invocation) {
            final ids = invocation.positionalArguments[0] as List<String>;
            // 1回目の並び替え（ID '1' が先頭）
            if (ids.first == '1') {
              return completer1.future;
            }
            // 2回目の並び替え
            return completer2.future;
          });

          final memoSub = container.listen(memoProvider, (_, _) {});
          await container.read(memoProvider.future);

          final initialIds = ['2', '1', '3'];

          // 1回目の並び替え（未完了のまま非同期で保留中）
          final future1 = container
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);

          // 1回目の保存中に素早く2回目の並び替えを実行
          final future2 = container
              .read(memoProvider.notifier)
              .reorderMemos(0, 2);

          // 1回目の保存をエラーで失敗させる
          completer1.completeError(Exception('First DB error'));
          await check(future1).throws<Exception>();

          // 1回目の失敗後、保存確認された順序（initialIds）にロールバックされていること
          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(initialIds);

          // 続いて2回目の保存もエラーで失敗させる
          completer2.completeError(Exception('Second DB error'));
          await check(future2).throws<Exception>();

          // 2回目の失敗後も、引き続き保存確認された順序（initialIds）が維持されていること
          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(initialIds);

          memoSub.close();
        },
      );

      test('reorderMemos: 保存待機中に検索条件が変更され失敗した場合、現在の検索結果が維持されること', () async {
        final completer = Completer<void>();

        when(
          () => mockMemoRepository.updateSortOrders(any(), any()),
        ).thenAnswer((_) => completer.future);

        final memoSub = container.listen(memoProvider, (_, _) {});
        await container.read(memoProvider.future);

        // 並び替え前の初期状態: ['2', '1', '3']
        // 並び替えを開始（非同期で保留中）
        final reorderFuture = container
            .read(memoProvider.notifier)
            .reorderMemos(0, 1);

        // 保存待機中に検索クエリを設定（'2' で検索）
        when(
          () => mockMemoRepository.watchFilteredMemos(
            any(),
            query: '2',
            category: any(named: 'category'),
            unsyncedOnly: any(named: 'unsyncedOnly'),
          ),
        ).thenAnswer(
          (_) => Stream.value([
            MemoModel(
              id: '2',
              userId: 'test_user_id',
              title: 'Title 2',
              content: 'Content 2',
              createdAt: DateTime(2026, 5, 2),
              updatedAt: DateTime(2026, 5, 2),
            ),
          ]),
        );

        container.read(memoFilterProvider.notifier).setQuery('2');
        // 検索によるストリームの更新を待つ
        await pumpEventQueue();

        // 検索結果として '2' のみが表示されていることを確認
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['2']);

        // 保存処理をエラーで失敗させる
        completer.completeError(Exception('DB Error'));
        await check(reorderFuture).throws<Exception>();

        // 保存失敗後も、検索前の一覧で上書きされず、検索結果（['2']）が維持されていること
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['2']);

        memoSub.close();
      });

      test(
        'reorderMemos: 保存待機中に別のメモが削除されて更新された場合、並び替え失敗のロールバックで削除済みメモが復活しないこと',
        () async {
          final streamController =
              StreamController<List<MemoModel>>.broadcast();
          final completer = Completer<void>();

          // ストリームController経由で初期一覧を提供
          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => streamController.stream);

          when(
            () => mockMemoRepository.updateSortOrders(any(), any()),
          ).thenAnswer((_) => completer.future);

          final memoSub = container.listen(memoProvider, (_, _) {});
          streamController.add(mockMemos);
          await container.read(memoProvider.future);

          // 初期順序: ['2', '1', '3']
          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['2', '1', '3']);

          // 並び替えを開始（保存処理は completer.future で待機中）
          final reorderFuture = container
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);

          // 保存待機中に、別の操作でメモ '3' が削除されたストリームが流れる
          final remainingMemos = [mockMemos[0], mockMemos[1]]; // '1' と '2' のみ
          when(
            () => mockMemoRepository.getLocalMemos(any()),
          ).thenAnswer((_) async => remainingMemos);
          streamController.add(remainingMemos);
          await pumpEventQueue();

          // 並び替え保存がエラーで失敗する
          completer.completeError(Exception('Reorder failed'));
          await check(reorderFuture).throws<Exception>();

          // ロールバック後、削除された '3' は復活せず、'2' と '1' が確定順に従って並んでいること
          final resultIds = container
              .read(memoProvider)
              .value!
              .map((m) => m.id)
              .toList();
          check(resultIds).deepEquals(['2', '1']);

          memoSub.close();
          await streamController.close();
        },
      );

      test('reorderMemos: '
          '保存待機中に新規メモが追加されStreamが反映された状態で失敗した場合、'
          '新規メモがDB位置を維持し末尾に移動しないこと', () async {
        final streamController = StreamController<List<MemoModel>>.broadcast();
        final completer = Completer<void>();
        addTearDown(streamController.close);

        final initialCustomMemos = [
          mockMemos[1].copyWith(sortOrder: 0), // '2'
          mockMemos[2].copyWith(sortOrder: 1), // '3'
          mockMemos[0].copyWith(sortOrder: 2), // '1'
        ];
        when(
          () => mockMemoRepository.watchAllMemos(any()),
        ).thenAnswer((_) => streamController.stream);
        when(
          () => mockMemoRepository.getLocalMemos(any()),
        ).thenAnswer((_) async => initialCustomMemos);
        when(
          () => mockMemoRepository.updateSortOrders(any(), any()),
        ).thenAnswer((_) => completer.future);

        container
            .read(memoFilterProvider.notifier)
            .setSortOrder(MemoSortOrder.custom);

        final memoSub = container.listen(memoProvider, (_, _) {});
        addTearDown(memoSub.close);
        streamController.add(initialCustomMemos);
        await container.read(memoProvider.future);

        // 初期順序（custom）: ['2', '3', '1']
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['2', '3', '1']);

        // 並び替えを開始（待機中は _activeReorderCount > 0 のため確定リストが更新されない）
        final reorderFuture = container
            .read(memoProvider.notifier)
            .reorderMemos(0, 2);

        // 保存待機中に新規メモ '4' が先頭（sortOrder: 0）に追加され、既存メモがシフトされる
        final newHeadMemo = MemoModel(
          id: '4',
          userId: 'test_user_id',
          title: 'New Head Memo',
          content: 'Inserted while reordering',
          createdAt: DateTime(2026, 5, 30),
          updatedAt: DateTime(2026, 5, 30),
        );
        final dbAfterInsert = [
          newHeadMemo,
          mockMemos[1].copyWith(sortOrder: 1),
          mockMemos[2].copyWith(sortOrder: 2),
          mockMemos[0].copyWith(sortOrder: 3),
        ];
        when(
          () => mockMemoRepository.getLocalMemos(any()),
        ).thenAnswer((_) async => dbAfterInsert);
        streamController.add(dbAfterInsert);
        await pumpEventQueue();

        // 保存が失敗してロールバックされる
        completer.completeError(Exception('Reorder failed'));
        await check(reorderFuture).throws<Exception>();

        // '4' が 999999 扱いで末尾に移動せず先頭（index 0）に維持され、既存メモも確定順のまま戻ること
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['4', '2', '3', '1']);
      });

      test('reorderMemos: '
          '保存待機中の新規・復元メモ追加がStream未反映のまま失敗しても、'
          '最新DB順を取得して正しい位置に配置されること', () async {
        final streamController = StreamController<List<MemoModel>>.broadcast();
        final completer = Completer<void>();
        addTearDown(streamController.close);

        final initialCustomMemos = [
          mockMemos[1].copyWith(sortOrder: 0), // '2'
          mockMemos[0].copyWith(sortOrder: 1), // '1'
          mockMemos[2].copyWith(sortOrder: 2), // '3'
        ];
        when(
          () => mockMemoRepository.watchAllMemos(any()),
        ).thenAnswer((_) => streamController.stream);
        when(
          () => mockMemoRepository.getLocalMemos(any()),
        ).thenAnswer((_) async => initialCustomMemos);
        when(
          () => mockMemoRepository.updateSortOrders(any(), any()),
        ).thenAnswer((_) => completer.future);

        container
            .read(memoFilterProvider.notifier)
            .setSortOrder(MemoSortOrder.custom);

        final memoSub = container.listen(memoProvider, (_, _) {});
        addTearDown(memoSub.close);
        streamController.add(initialCustomMemos);
        await container.read(memoProvider.future);

        // 並び替えを開始
        final reorderFuture = container
            .read(memoProvider.notifier)
            .reorderMemos(0, 2);

        // DBには先頭新規メモ '4'（sortOrder: 0）と中間復元メモ '5'（sortOrder: 2）が存在するが、
        // Stream通知がまだUI状態に反映されていない状態を模擬（さらにDB返却順も未ソートで検証）
        final newHeadMemo = MemoModel(
          id: '4',
          userId: 'test_user_id',
          title: 'New Head Memo',
          content: 'Head content',
          createdAt: DateTime(2026, 5, 30),
          updatedAt: DateTime(2026, 5, 30),
        );
        final restoredMidMemo = MemoModel(
          id: '5',
          userId: 'test_user_id',
          title: 'Restored Middle Memo',
          content: 'Middle content',
          createdAt: DateTime(2026, 5),
          updatedAt: DateTime(2026, 5),
          sortOrder: 2,
        );
        when(() => mockMemoRepository.getLocalMemos(any())).thenAnswer(
          (_) async => [
            mockMemos[2].copyWith(sortOrder: 4), // '3'
            restoredMidMemo, // sortOrder: 2
            mockMemos[0].copyWith(sortOrder: 3), // '1'
            newHeadMemo, // sortOrder: 0
            mockMemos[1].copyWith(sortOrder: 1), // '2'
          ],
        );

        // Stream未反映のまま並び替え保存が失敗する
        completer.completeError(Exception('Reorder failed'));
        await check(reorderFuture).throws<Exception>();

        // 既存メモ ['2', '1', '3'] のロールバックを保ちつつ、
        // 先頭追加 '4' は先頭、中間復元 '5' は中間に配置されること
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['4', '2', '5', '1', '3']);
      });

      test('reorderMemos: '
          'ロールバック時のgetLocalMemos取得自体が失敗しても'
          'メモリ上の状態からフォールバック復元し元の例外を再スローすること', () async {
        final streamController = StreamController<List<MemoModel>>.broadcast();
        final completer = Completer<void>();
        addTearDown(streamController.close);

        when(
          () => mockMemoRepository.watchAllMemos(any()),
        ).thenAnswer((_) => streamController.stream);
        when(
          () => mockMemoRepository.updateSortOrders(any(), any()),
        ).thenAnswer((_) => completer.future);
        when(
          () => mockMemoRepository.getLocalMemos(any()),
        ).thenThrow(Exception('DB Read Error'));

        final memoSub = container.listen(memoProvider, (_, _) {});
        addTearDown(memoSub.close);
        streamController.add(mockMemos);
        await container.read(memoProvider.future);

        final reorderFuture = container
            .read(memoProvider.notifier)
            .reorderMemos(0, 1);

        final newHeadMemo = MemoModel(
          id: '4',
          userId: 'test_user_id',
          title: 'New Head Memo',
          content: 'Head content',
          createdAt: DateTime(2026, 5, 30),
          updatedAt: DateTime(2026, 5, 30),
        );
        streamController.add([newHeadMemo, ...mockMemos]);
        await pumpEventQueue();

        final writeException = Exception('Write Error');
        completer.completeError(writeException);
        await check(reorderFuture).throws<Exception>();

        // getLocalMemos が失敗してもクラッシュせず、現在のstateをもとにロールバックされること
        check(
          container.read(memoProvider).value!.map((m) => m.id).toList(),
        ).deepEquals(['4', '2', '1', '3']);
      });

      test(
        'reorderMemos: ロールバック時のgetLocalMemos待機中に検索条件が変更された場合、検索結果を上書きしないこと',
        () async {
          final updateCompleter = Completer<void>();
          final fetchCompleter = Completer<List<MemoModel>>();

          when(
            () => mockMemoRepository.updateSortOrders(any(), any()),
          ).thenAnswer((_) => updateCompleter.future);
          when(
            () => mockMemoRepository.getLocalMemos(any()),
          ).thenAnswer((_) => fetchCompleter.future);

          final memoSub = container.listen(memoProvider, (_, _) {});
          addTearDown(memoSub.close);
          await container.read(memoProvider.future);

          final reorderFuture = container
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);

          // updateSortOrders を失敗させ、getLocalMemos の待機状態に入れる
          updateCompleter.completeError(Exception('Write Error'));
          await pumpEventQueue();

          // getLocalMemos の完了を待つ間に検索フィルタを設定
          when(
            () => mockMemoRepository.watchFilteredMemos(
              any(),
              query: '2',
              category: any(named: 'category'),
              unsyncedOnly: any(named: 'unsyncedOnly'),
            ),
          ).thenAnswer((_) => Stream.value([mockMemos[1]]));
          container.read(memoFilterProvider.notifier).setQuery('2');
          await pumpEventQueue();

          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['2']);

          fetchCompleter.complete(mockMemos);
          await check(reorderFuture).throws<Exception>();

          // 検索結果 ['2'] がロールバックで上書きされないこと
          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['2']);
        },
      );

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

      test(
        'reorderMemos: 範囲外のoldIndex/targetIndexは無視され、状態やカウンターが汚染されないこと',
        () async {
          final streamController =
              StreamController<List<MemoModel>>.broadcast();
          when(
            () => mockMemoRepository.watchAllMemos(any()),
          ).thenAnswer((_) => streamController.stream);

          final memoSub = container.listen(memoProvider, (_, _) {});
          streamController.add(mockMemos);
          await container.read(memoProvider.future);

          // 初期順序: ['2', '1', '3']
          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['2', '1', '3']);

          // 範囲外の各種パターン（負数・リスト長以上）を実行しても例外にならず中断すること
          await container.read(memoProvider.notifier).reorderMemos(-1, 0);
          await container.read(memoProvider.notifier).reorderMemos(3, 0);
          await container.read(memoProvider.notifier).reorderMemos(0, -1);
          await container.read(memoProvider.notifier).reorderMemos(0, 3);

          // 保存処理は一度も呼ばれないこと
          verifyNever(() => mockMemoRepository.updateSortOrders(any(), any()));
          // 表示中の並び順が維持されていること
          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['2', '1', '3']);

          // カウンター（_activeReorderCount）が増えていないことを確認するため、
          // 順序が変わった新しい一覧（'3' を最新にした ['3', '2', '1']）をストリームで流す
          final updatedStreamMemos = [
            mockMemos[0],
            mockMemos[1],
            mockMemos[2].copyWith(createdAt: DateTime(2026, 5, 20)),
          ];
          when(
            () => mockMemoRepository.getLocalMemos(any()),
          ).thenAnswer((_) async => updatedStreamMemos);
          streamController.add(updatedStreamMemos);
          await pumpEventQueue();

          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['3', '2', '1']);

          // 正常な並び替えをわざと失敗させ、直前の確定順 ['3', '2', '1'] へ正しくロールバックされること
          // （カウンターが壊れていれば古い ['2', '1', '3'] に戻ってしまう）
          when(
            () => mockMemoRepository.updateSortOrders(any(), any()),
          ).thenThrow(Exception('DB Error'));

          await check(
            container.read(memoProvider.notifier).reorderMemos(0, 1),
          ).throws<Exception>();

          check(
            container.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['3', '2', '1']);

          memoSub.close();
          await streamController.close();
        },
      );

      ProviderContainer createAuthContainer() {
        final authContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(_testUserIdProvider),
            ),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
            loggerProvider.overrideWithValue(Talker()),
          ],
        );
        addTearDown(authContainer.dispose);
        return authContainer;
      }

      final userAMemos = [
        MemoModel(
          id: 'a1',
          userId: 'user_a',
          title: 'A1',
          content: 'C1',
          createdAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 2),
        ),
        MemoModel(
          id: 'a2',
          userId: 'user_a',
          title: 'A2',
          content: 'C2',
          createdAt: DateTime(2026, 5),
          updatedAt: DateTime(2026, 5),
        ),
      ];

      test(
        'reorderMemos: 保存待機中に別ユーザーへ切り替わって失敗した場合、旧ユーザーのメモで状態が復元されないこと',
        () async {
          final completerA1 = Completer<void>();
          final completerA2 = Completer<void>();
          var callCount = 0;
          final userAController = StreamController<List<MemoModel>>.broadcast();
          final userBController = StreamController<List<MemoModel>>.broadcast();
          addTearDown(() async {
            await userAController.close();
            await userBController.close();
          });

          when(
            () => mockMemoRepository.watchAllMemos('user_a'),
          ).thenAnswer((_) => userAController.stream);
          when(
            () => mockMemoRepository.watchAllMemos('user_b'),
          ).thenAnswer((_) => userBController.stream);
          when(
            () => mockMemoRepository.updateSortOrders(any(), 'user_a'),
          ).thenAnswer((_) {
            callCount++;
            return callCount == 1 ? completerA1.future : completerA2.future;
          });

          final authContainer = createAuthContainer();
          final memoSub = authContainer.listen(memoProvider, (_, _) {});
          addTearDown(memoSub.close);

          userAController.add(userAMemos);
          await authContainer.read(memoProvider.future);

          // user_a で2件の並び替えを開始（保存待機中）
          final reorderFuture1 = authContainer
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);
          final reorderFuture2 = authContainer
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);

          // 待機中に別アカウント（user_b）へ切り替え（user_b はまだロード中）
          authContainer.read(_testUserIdProvider.notifier).userId = 'user_b';
          await pumpEventQueue();

          // 1. user_b ロード中に旧ユーザーAの1つ目が失敗しても、
          //    AsyncLoading のまま（AsyncData に復元されないこと）
          completerA1.completeError(Exception('User A DB Error 1'));
          await reorderFuture1;
          check(
            authContainer.read(memoProvider),
          ).isA<AsyncLoading<List<MemoModel>>>();

          // user_b のデータが届けば正常に表示されること
          final userBMemos = [
            MemoModel(
              id: 'b1',
              userId: 'user_b',
              title: 'B1',
              content: 'C1',
              createdAt: DateTime(2026, 5, 3),
              updatedAt: DateTime(2026, 5, 3),
            ),
          ];
          userBController.add(userBMemos);
          await pumpEventQueue();
          check(
            authContainer.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['b1']);

          // 2. user_b 表示後に旧ユーザーAの2つ目が失敗 → user_b の表示がそのまま維持されること
          completerA2.completeError(Exception('User A DB Error 2'));
          await reorderFuture2;
          check(
            authContainer.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['b1']);
        },
      );

      test(
        'reorderMemos: 保存待機中にログアウト→同一ユーザーで再ログインした場合、成功時も旧結果が破棄されること',
        () async {
          final completer1 = Completer<void>();
          final streamController =
              StreamController<List<MemoModel>>.broadcast();
          addTearDown(streamController.close);

          when(
            () => mockMemoRepository.watchAllMemos('user_a'),
          ).thenAnswer((_) => streamController.stream);
          when(
            () => mockMemoRepository.updateSortOrders(any(), 'user_a'),
          ).thenAnswer((_) => completer1.future);

          final authContainer = createAuthContainer();
          final memoSub = authContainer.listen(memoProvider, (_, _) {});
          addTearDown(memoSub.close);

          streamController.add(userAMemos);
          await authContainer.read(memoProvider.future);

          // 旧セッション（user_a）で並び替えを開始
          final reorderFuture = authContainer
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);

          // 待機中にログアウト → 同じ user_a で再ログイン（認証世代だけが進む）
          authContainer.read(_testUserIdProvider.notifier).userId = null;
          await pumpEventQueue();
          authContainer.read(_testUserIdProvider.notifier).userId = 'user_a';
          await pumpEventQueue();
          streamController.add(userAMemos);
          await authContainer.read(memoProvider.future);

          // 旧セッションの並び替え保存が完了
          completer1.complete();
          await reorderFuture;

          // 旧セッションの完了結果で新セッションのソート順が勝手に custom へ変更されていないこと
          check(
            authContainer.read(memoFilterProvider).sortOrder,
          ).equals(MemoSortOrder.createdAtDesc);
        },
      );

      test(
        'reorderMemos: 保存待機中にプロバイダが破棄（dispose）された場合、成功・失敗いずれも安全に破棄されること',
        () async {
          for (final shouldFail in [false, true]) {
            final completer = Completer<void>();
            when(
              () => mockMemoRepository.watchAllMemos(any()),
            ).thenAnswer((_) => Stream.value(mockMemos));
            when(
              () => mockMemoRepository.updateSortOrders(any(), any()),
            ).thenAnswer((_) => completer.future);

            final disposableContainer = ProviderContainer(
              overrides: [
                currentUserIdProvider.overrideWithValue('test_user_id'),
                memoRepositoryProvider.overrideWithValue(mockMemoRepository),
                isOnlineProvider.overrideWithValue(false),
                loggerProvider.overrideWithValue(Talker()),
              ],
            );

            final sub = disposableContainer.listen(memoProvider, (_, _) {});
            await disposableContainer.read(memoProvider.future);

            final reorderFuture = disposableContainer
                .read(memoProvider.notifier)
                .reorderMemos(0, 1);

            // 待機中にコンテナを破棄（ref.mounted == false）
            sub.close();
            disposableContainer.dispose();

            if (shouldFail) {
              completer.completeError(Exception('Disposed DB Error'));
            } else {
              completer.complete();
            }

            // UnmountedRefException や再スローが起きず安全に完了すること
            await reorderFuture;
          }
        },
      );

      test(
        'reorderMemos: ロールバック時のgetLocalMemos待機中に別ユーザー切替やプロバイダ破棄が起きても安全に破棄されること',
        () async {
          final updateCompleter = Completer<void>();
          final fetchCompleter = Completer<List<MemoModel>>();
          final userAController = StreamController<List<MemoModel>>.broadcast();
          final userBController = StreamController<List<MemoModel>>.broadcast();
          addTearDown(() async {
            await userAController.close();
            await userBController.close();
          });

          when(
            () => mockMemoRepository.watchAllMemos('user_a'),
          ).thenAnswer((_) => userAController.stream);
          when(
            () => mockMemoRepository.watchAllMemos('user_b'),
          ).thenAnswer((_) => userBController.stream);
          when(
            () => mockMemoRepository.updateSortOrders(any(), 'user_a'),
          ).thenAnswer((_) => updateCompleter.future);
          when(
            () => mockMemoRepository.getLocalMemos('user_a'),
          ).thenAnswer((_) => fetchCompleter.future);

          final authContainer = createAuthContainer();
          final memoSub = authContainer.listen(memoProvider, (_, _) {});
          addTearDown(memoSub.close);

          userAController.add(userAMemos);
          await authContainer.read(memoProvider.future);

          final reorderFuture = authContainer
              .read(memoProvider.notifier)
              .reorderMemos(0, 1);

          updateCompleter.completeError(Exception('User A DB Error'));
          await pumpEventQueue();

          // getLocalMemos の待機中に user_b へ切り替え
          authContainer.read(_testUserIdProvider.notifier).userId = 'user_b';
          await pumpEventQueue();

          final userBMemos = [
            MemoModel(
              id: 'b1',
              userId: 'user_b',
              title: 'B1',
              content: 'C1',
              createdAt: DateTime(2026, 5, 3),
              updatedAt: DateTime(2026, 5, 3),
            ),
          ];
          userBController.add(userBMemos);
          await pumpEventQueue();

          fetchCompleter.complete(userAMemos);
          await reorderFuture;

          // user_b の表示が user_a のロールバックで上書きされていないこと
          check(
            authContainer.read(memoProvider).value!.map((m) => m.id).toList(),
          ).deepEquals(['b1']);
        },
      );

      test('restoreMemo: ログイン時にリポジトリのrestoreMemoが呼ばれ、未ログイン時は何もしないこと', () async {
        when(
          () => mockMemoRepository.restoreMemo(
            any(),
            any(),
            waitForRemoteSync: any(named: 'waitForRemoteSync'),
          ),
        ).thenAnswer((_) async {});

        // ログイン時
        await container.read(memoProvider.notifier).restoreMemo('memo-1');
        verify(
          () => mockMemoRepository.restoreMemo(
            'memo-1',
            'test_user_id',
            waitForRemoteSync: false,
          ),
        ).called(1);

        // expectedUserId が現在ユーザーと不一致の場合は何もしない
        await container
            .read(memoProvider.notifier)
            .restoreMemo('memo-1', expectedUserId: 'other_user_id');
        verifyNever(
          () => mockMemoRepository.restoreMemo(
            'memo-1',
            any(),
            waitForRemoteSync: any(named: 'waitForRemoteSync'),
          ),
        );

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
        verifyNever(
          () => mockMemoRepository.restoreMemo(
            'memo-1',
            any(),
            waitForRemoteSync: any(named: 'waitForRemoteSync'),
          ),
        );
      });

      test('retainForUndo: 解放クロージャを呼ぶまでNotifierが保持され、解放後に破棄されること', () async {
        when(
          () => mockMemoRepository.restoreMemo(
            any(),
            any(),
            waitForRemoteSync: any(named: 'waitForRemoteSync'),
          ),
        ).thenAnswer((_) async {});

        final sub = container.listen(memoProvider, (_, _) {});
        final notifier = container.read(memoProvider.notifier);
        final release = notifier.retainForUndo();

        // 監視を解除しても retain 中は ref が有効で restoreMemo が動作する
        sub.close();
        await container.pump();

        await notifier.restoreMemo('memo-retained');
        verify(
          () => mockMemoRepository.restoreMemo(
            'memo-retained',
            'test_user_id',
            waitForRemoteSync: false,
          ),
        ).called(1);

        // 保持を解放すると次のポンプで自動破棄される
        release();
        await container.pump();
      });
    });
  });
}
