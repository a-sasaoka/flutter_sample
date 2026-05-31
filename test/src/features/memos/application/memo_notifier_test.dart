import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

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
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build() は repository.getAllMemos() の結果を返すこと', () async {
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
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => mockMemos);

      final subscription = container.listen(memoProvider, (_, _) {});

      final memos = await container.read(memoProvider.future);

      check(memos).deepEquals(mockMemos);
      verify(() => mockMemoRepository.getAllMemos()).called(1);

      subscription.close();
    });

    test('addMemo は repository.addMemo() を呼び、状態を再取得すること', () async {
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => []);
      when(
        () => mockMemoRepository.addMemo(any(), any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).addMemo('タイトル', '内容');
      // invalidate後に再取得を待つ
      await container.read(memoProvider.future);

      verify(() => mockMemoRepository.addMemo('タイトル', '内容')).called(1);
      // build() が合計2回呼ばれる（初回 + addMemo後のinvalidate）
      verify(() => mockMemoRepository.getAllMemos()).called(2);

      subscription.close();
    });

    test('deleteMemo は repository.deleteMemo() を呼び、状態を再取得すること', () async {
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => []);
      when(
        () => mockMemoRepository.deleteMemo(any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).deleteMemo('id1');
      // invalidate後に再取得を待つ
      await container.read(memoProvider.future);

      verify(() => mockMemoRepository.deleteMemo('id1')).called(1);
      verify(() => mockMemoRepository.getAllMemos()).called(2);

      subscription.close();
    });

    test('sync は repository.syncUnsentMemos() を呼び、状態を再取得すること', () async {
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => []);
      when(
        () => mockMemoRepository.syncUnsentMemos(),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      await container.read(memoProvider.future);
      await container.read(memoProvider.notifier).sync();
      // invalidate後に再取得を待つ
      await container.read(memoProvider.future);

      verify(() => mockMemoRepository.syncUnsentMemos()).called(1);
      verify(() => mockMemoRepository.getAllMemos()).called(2);

      subscription.close();
    });

    test('repository.getAllMemos() でエラーが発生した場合、状態にエラーが保持されること', () async {
      final exception = Exception('読み込み失敗');

      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => throw exception);

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
          () => mockMemoRepository.getAllMemos(),
        ).thenAnswer((_) async => mockMemos);
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
