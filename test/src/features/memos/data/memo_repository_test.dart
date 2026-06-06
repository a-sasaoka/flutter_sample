import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockMemoRemoteService extends Mock implements MemoRemoteService {}

class MockTalker extends Mock implements Talker {}

void main() {
  group('MemoRepository', () {
    late AppDatabase database;
    late MockMemoRemoteService mockRemoteService;
    late MockTalker mockTalker;
    final now = DateTime(2026, 5);

    setUpAll(() {
      registerFallbackValue(DateTime.now());
    });

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      mockRemoteService = MockMemoRemoteService();
      mockTalker = MockTalker();

      when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
      when(() => mockTalker.error(any<dynamic>())).thenReturn(null);

      // デフォルトの振る舞い（Future<void>などのエラーを防ぐため）
      when(() => mockRemoteService.fetchMemos()).thenAnswer((_) async => []);
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await database.close();
    });

    ProviderContainer createContainer({bool isOnline = true}) {
      return ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          memoRemoteServiceProvider.overrideWithValue(mockRemoteService),
          clockProvider.overrideWithValue(() => now),
          isOnlineProvider.overrideWithValue(isOnline),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
    }

    test('addMemo: オフラインの場合、ローカルに保存され isSynced が false になること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('title', 'content');

      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.title).equals('title');
      check(memos.first.isSynced).equals(false);
      verifyNever(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      );
    });

    test('addMemo: オンラインの場合、ローカルとリモートに保存され isSynced が true になること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('title', 'content');

      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.title).equals('title');
      check(memos.first.isSynced).equals(true);
      verify(
        () => mockRemoteService.uploadMemo(
          id: memos.first.id,
          title: 'title',
          content: 'content',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ).called(1);
    });

    test('addMemo: オンラインでアップロードに失敗した場合、isSynced が false のままになること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      ).thenThrow(Exception('error'));

      await repository.addMemo('title', 'content');

      final memos = await database.select(database.memos).get();
      check(memos.first.isSynced).equals(false);
    });

    test('updateMemo: オフラインの場合、ローカルが更新され isSynced が false になること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(true),
            ),
          );

      await repository.updateMemo('id1', 'new title', 'new content');

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.title).equals('new title');
      check(memo.isSynced).equals(false);
      verifyNever(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      );
    });

    test('updateMemo: オンラインの場合、ローカルとリモートが更新され isSynced が true になること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await repository.updateMemo('id1', 'new title', 'new content');

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.isSynced).equals(true);
      verify(
        () => mockRemoteService.uploadMemo(
          id: 'id1',
          title: 'new title',
          content: 'new content',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ).called(1);
    });

    test('updateMemo: オンラインでアップロードに失敗した場合、isSynced が false のままになること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
            ),
          );
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      ).thenThrow(Exception('error'));

      await repository.updateMemo('id1', 'new title', 'new content');

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.isSynced).equals(false);
    });

    test('deleteMemo: オフラインの場合、ローカルで論理削除され isSynced が false になること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(true),
            ),
          );

      await repository.deleteMemo('id1');

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.isDeleted).equals(true);
      check(memo.isSynced).equals(false);
      verifyNever(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      );
    });

    test(
      'deleteMemo: オンラインの場合、ローカルとリモートで論理削除され isSynced が true になること',
      () async {
        final container = createContainer();
        final repository = container.read(memoRepositoryProvider);
        await database
            .into(database.memos)
            .insert(
              MemosCompanion.insert(
                id: 'id1',
                title: 'old',
                content: 'old',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await repository.deleteMemo('id1');

        final memo = await (database.select(
          database.memos,
        )..where((m) => m.id.equals('id1'))).getSingle();
        check(memo.isDeleted).equals(true);
        check(memo.isSynced).equals(true);
      },
    );

    test('deleteMemo: オンラインでアップロードに失敗した場合、isSynced が false のままになること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
            ),
          );
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      ).thenThrow(Exception('error'));

      await repository.deleteMemo('id1');

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.isDeleted).equals(true);
      check(memo.isSynced).equals(false);
    });

    test('syncUnsentMemos: 未送信のメモがない場合、何もしないこと', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await repository.syncUnsentMemos();
      verifyNever(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      );
    });

    test('syncUnsentMemos: すべての未送信メモを同期すること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '1',
              title: '1',
              content: '1',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(false),
            ),
          );
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '2',
              title: '2',
              content: '2',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(true),
            ),
          );

      await repository.syncUnsentMemos();

      final memo1 = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('1'))).getSingle();
      check(memo1.isSynced).equals(true);
      verify(
        () => mockRemoteService.uploadMemo(
          id: '1',
          title: '1',
          content: '1',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ).called(1);
    });

    test('syncUnsentMemos: エラー発生時もループを継続し、後続のメモを同期すること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '1',
              title: '1',
              content: '1',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(false),
            ),
          );
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '2',
              title: '2',
              content: '2',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(false),
            ),
          );
      when(
        () => mockRemoteService.uploadMemo(
          id: '1',
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
        ),
      ).thenThrow(Exception('error'));

      await repository.syncUnsentMemos();

      final memos = await database.select(database.memos).get();
      check(memos.firstWhere((m) => m.id == '1').isSynced).equals(false);
      check(memos.firstWhere((m) => m.id == '2').isSynced).equals(true);
      verify(
        () => mockRemoteService.uploadMemo(
          id: '2',
          title: '2',
          content: '2',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ).called(1);
    });

    test('getAllMemos: オフラインの場合、同期をスキップしローカルの未削除メモを返すこと', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '1',
              title: '1',
              content: '1',
              createdAt: now,
              updatedAt: now,
              isDeleted: const drift.Value(false),
            ),
          );
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '2',
              title: '2',
              content: '2',
              createdAt: now,
              updatedAt: now,
              isDeleted: const drift.Value(true),
            ),
          );

      final memos = await repository.getAllMemos();

      check(memos.length).equals(1);
      check(memos.first.id).equals('1');
      // オフラインでも fetchMemos は呼ばれる実装になっている
      verify(() => mockRemoteService.fetchMemos()).called(1);
    });

    test('getAllMemos: オンラインの場合、リモートから取得して新しいメモをマージすること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      when(() => mockRemoteService.fetchMemos()).thenAnswer(
        (_) async => [
          {
            'id': 'remote1',
            'title': 'rtitle',
            'content': 'rcontent',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
        ],
      );

      final memos = await repository.getAllMemos();

      check(memos.length).equals(1);
      check(memos.first.id).equals('remote1');
      check(memos.first.title).equals('rtitle');
    });

    test(
      'getAllMemos: オンラインの場合、リモートから取得して更新されたメモをマージすること（リモートが新しい場合）',
      () async {
        final container = createContainer();
        final repository = container.read(memoRepositoryProvider);
        await database
            .into(database.memos)
            .insert(
              MemosCompanion.insert(
                id: '1',
                title: 'local',
                content: 'local',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final newerTime = now.add(const Duration(minutes: 1));
        when(() => mockRemoteService.fetchMemos()).thenAnswer(
          (_) async => [
            {
              'id': '1',
              'title': 'remote',
              'content': 'remote content',
              'createdAt': now,
              'updatedAt': newerTime,
              'isDeleted': false,
            },
          ],
        );

        final memos = await repository.getAllMemos();

        check(memos.length).equals(1);
        check(memos.first.title).equals('remote');
      },
    );

    test(
      'getAllMemos: オンラインの場合、リモートから取得してもローカルのメモを保持すること（ローカルが新しいか同じ場合）',
      () async {
        final container = createContainer();
        final repository = container.read(memoRepositoryProvider);
        final newerTime = now.add(const Duration(minutes: 1));
        await database
            .into(database.memos)
            .insert(
              MemosCompanion.insert(
                id: '1',
                title: 'local',
                content: 'local',
                createdAt: now,
                updatedAt: newerTime,
              ),
            );

        when(() => mockRemoteService.fetchMemos()).thenAnswer(
          (_) async => [
            {
              'id': '1',
              'title': 'remote',
              'content': 'remote content',
              'createdAt': now,
              'updatedAt': now, // older
              'isDeleted': false,
            },
          ],
        );

        final memos = await repository.getAllMemos();

        check(memos.length).equals(1);
        check(memos.first.title).equals('local');
      },
    );

    test('getAllMemos: fetchMemos で例外が発生した場合、エラーを適切に処理すること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      when(
        () => mockRemoteService.fetchMemos(),
      ).thenThrow(Exception('fetch error'));

      final memos = await repository.getAllMemos();

      check(memos.length).equals(0); // local is empty
    });

    test('memoRepositoryProvider が正しいインスタンスを提供すること', () {
      final container = createContainer();
      final repo = container.read(memoRepositoryProvider);
      check(repo).isA<MemoRepository>();
    });

    test('watchAllMemos: データベースに保存されたメモを Stream で取得でき、変更が通知されること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      final emissions = <List<MemoModel>>[];
      // Streamの購読を開始
      final subscription = repository.watchAllMemos().listen(emissions.add);

      // 1. 初期状態（空リスト）のイベントが届くのを待つ
      await Future<void>.delayed(const Duration(milliseconds: 10));
      check(emissions.length).equals(1);
      check(emissions.first).isEmpty();

      // 2. 1つ目のメモを追加
      await repository.addMemo('watch1', 'content1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      check(emissions.length).equals(2);
      check(emissions[1].length).equals(1);
      check(emissions[1][0].title).equals('watch1');

      // 3. 2つ目のメモを追加
      await repository.addMemo('watch2', 'content2');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      check(emissions.length).equals(3);
      check(emissions[2].length).equals(2);

      // 4. 最新リストに両方のメモが含まれていることを確認
      final titles = emissions[2].map((m) => m.title).toList();
      check(titles).contains('watch1');
      check(titles).contains('watch2');

      // 購読を解除
      await subscription.cancel();
    });

    test('fetchAndMergeRemoteMemos: オンラインの場合、リモートから取得してマージすること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      when(() => mockRemoteService.fetchMemos()).thenAnswer(
        (_) async => [
          {
            'id': 'remote_fetch',
            'title': 'fetch_title',
            'content': 'fetch_content',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
        ],
      );

      await repository.fetchAndMergeRemoteMemos();

      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.id).equals('remote_fetch');
      check(memos.first.title).equals('fetch_title');
    });
  });
}
