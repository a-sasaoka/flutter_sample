import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('MemoRemoteService', () {
    late MemoRemoteService service;

    setUp(() {
      service = MemoRemoteService();
    });

    test('初期状態ではfetchMemosは空のリストを返すこと', () async {
      final result = await service.fetchMemos();
      expect(result, isEmpty);
    });

    test('uploadMemoで新しいメモを追加し、fetchMemosで取得できること', () async {
      final now = DateTime(2026, 5, 2);

      await service.uploadMemo(
        id: 'memo1',
        title: 'テストタイトル',
        content: 'テストコンテンツ',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      final result = await service.fetchMemos();
      expect(result.length, 1);
      expect(result.first['id'], 'memo1');
      expect(result.first['title'], 'テストタイトル');
      expect(result.first['content'], 'テストコンテンツ');
      expect(result.first['createdAt'], now);
      expect(result.first['updatedAt'], now);
      expect(result.first['isDeleted'], false);
    });

    test('uploadMemoで既存のメモを更新できること', () async {
      final now = DateTime(2026, 5, 2);

      // 初回の追加
      await service.uploadMemo(
        id: 'memo1',
        title: '古いタイトル',
        content: '古いコンテンツ',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      // 更新
      final updatedTime = now.add(const Duration(hours: 1));
      await service.uploadMemo(
        id: 'memo1', // 同じID
        title: '新しいタイトル',
        content: '新しいコンテンツ',
        createdAt: now,
        updatedAt: updatedTime,
        isDeleted: true,
      );

      final result = await service.fetchMemos();
      expect(result.length, 1); // 追加されず上書きされていること
      expect(result.first['id'], 'memo1');
      expect(result.first['title'], '新しいタイトル');
      expect(result.first['content'], '新しいコンテンツ');
      expect(result.first['createdAt'], now);
      expect(result.first['updatedAt'], updatedTime);
      expect(result.first['isDeleted'], true);
    });
  });

  group('memoRemoteServiceProvider', () {
    test('Provider経由でMemoRemoteServiceのインスタンスを取得できること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(memoRemoteServiceProvider);
      expect(service, isA<MemoRemoteService>());
    });
  });
}
