import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('MemoRepository', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          currentDateTimeProvider.overrideWithValue(DateTime(2026, 5)),
        ],
      );
    });

    tearDown(() async {
      await database.close();
      container.dispose();
    });

    test('addMemo は新しいメモをデータベースに保存する', () async {
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('タイトル', 'コンテンツ');

      final memos = await database.select(database.memos).get();
      expect(memos.length, 1);
      expect(memos.first.title, 'タイトル');
      expect(memos.first.content, 'コンテンツ');
      expect(memos.first.createdAt, DateTime(2026, 5));
    });

    test('getAllMemos はデータベースに保存されているすべてのメモを取得する', () async {
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('タイトル1', 'コンテンツ1');
      await repository.addMemo('タイトル2', 'コンテンツ2');

      final memos = await repository.getAllMemos();
      expect(memos.length, 2);
      expect(memos[0].title, 'タイトル1');
      expect(memos[1].title, 'タイトル2');
    });

    test('memoRepositoryProvider は MemoRepository のインスタンスを返すこと', () {
      final repository = container.read(memoRepositoryProvider);
      expect(repository, isA<MemoRepository>());
    });
  });
}
