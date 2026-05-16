import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
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

      expect(memos, mockMemos);
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
      expect(state.hasError, isTrue);
      expect(state.error, exception);

      subscription.close();
    });
  });
}
