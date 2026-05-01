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
          id: 1,
          title: 'テストタイトル',
          content: 'テストコンテンツ',
          createdAt: DateTime(2026, 5),
        ),
      ];

      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => mockMemos);

      // AutoDisposeを防ぐためにlistenする（GEMINI.mdルール準拠）
      final subscription = container.listen(memoProvider, (_, _) {});

      // 初回の状態（AsyncLoading）からデータ取得完了（AsyncData）を待つ
      final memos = await container.read(memoProvider.future);

      expect(memos, mockMemos);
      verify(() => mockMemoRepository.getAllMemos()).called(1);

      subscription.close();
    });

    test('addMemo は repository.addMemo() を呼び、状態を再取得（invalidate）すること', () async {
      final mockMemos = [
        MemoModel(
          id: 1,
          title: 'テストタイトル',
          content: 'テストコンテンツ',
          createdAt: DateTime(2026, 5),
        ),
      ];

      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => mockMemos);
      when(
        () => mockMemoRepository.addMemo(any(), any()),
      ).thenAnswer((_) async {});

      final subscription = container.listen(memoProvider, (_, _) {});

      // まず初期状態を取得してビルドを完了させる
      await container.read(memoProvider.future);
      verify(() => mockMemoRepository.getAllMemos()).called(1);

      // メモを追加
      await container.read(memoProvider.notifier).addMemo('新規タイトル', '新規コンテンツ');

      // リポジトリのaddMemoが呼ばれたことを確認
      verify(() => mockMemoRepository.addMemo('新規タイトル', '新規コンテンツ')).called(1);

      // invalidateSelf によって再度 getAllMemos が呼ばれることを確認
      await container.read(memoProvider.future);

      // 最初とinvalidate後で合計2回呼ばれるはず
      verify(() => mockMemoRepository.getAllMemos()).called(1);

      subscription.close();
    });

    test('repository.getAllMemos() でエラーが発生した場合、状態にエラーが保持されること', () async {
      final exception = Exception('読み込み失敗');

      // getAllMemos が非同期エラーを投げるように設定
      when(
        () => mockMemoRepository.getAllMemos(),
      ).thenAnswer((_) async => throw exception);

      // 状態の変化を監視（AutoDispose防止）
      final subscription = container.listen(memoProvider, (_, _) {});

      // 状態が更新されるまで待機
      // hasError が true になるまで最大10回 microtask を回す
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
