import 'dart:async';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/auth/data/token_interceptor.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/data/memos_dao.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockMemoRemoteService extends Mock implements MemoRemoteService {}

class MockTokenStorage extends Mock implements TokenStorage {}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

class _HookedMemosDao extends MemosDao {
  _HookedMemosDao(
    super.attachedDatabase, {
    this.onBeforeGetMemoById,
    this.onBeforeGetMemosByIds,
  });

  final Future<void> Function()? onBeforeGetMemoById;
  final Future<void> Function()? onBeforeGetMemosByIds;

  @override
  Future<Memo> getMemoById(String id, String userId) async {
    await onBeforeGetMemoById?.call();
    return await super.getMemoById(id, userId);
  }

  @override
  Future<List<Memo>> getMemosByIds(List<String> ids, String userId) async {
    await onBeforeGetMemosByIds?.call();
    return await super.getMemosByIds(ids, userId);
  }
}

class _TestUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'test-user-id';

  String? get userId => state;

  set userId(String? id) => state = id;
}

final _testUserIdProvider = NotifierProvider<_TestUserIdNotifier, String?>(
  _TestUserIdNotifier.new,
);

class HandleCall {
  const HandleCall({required this.exception, this.stackTrace, this.message});

  final Object exception;
  final StackTrace? stackTrace;
  final dynamic message;
}

class SpyTalker extends Talker {
  SpyTalker() : super(settings: TalkerSettings(enabled: false));

  final List<HandleCall> handleCalls = [];

  @override
  void handle(Object exception, [StackTrace? stackTrace, dynamic msg]) {
    handleCalls.add(
      HandleCall(exception: exception, stackTrace: stackTrace, message: msg),
    );
    super.handle(exception, stackTrace, msg);
  }
}

void main() {
  group('MemoRepository', () {
    late AppDatabase database;
    late MockMemoRemoteService mockRemoteService;
    late SpyTalker spyTalker;
    final now = DateTime(2026, 5);
    const testUserId = 'test-user-id';
    const otherUserId = 'other-user-id';

    setUpAll(() {
      registerFallbackValue(DateTime.now());
    });

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      mockRemoteService = MockMemoRemoteService();
      spyTalker = SpyTalker();

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
          expectedUserId: any(named: 'expectedUserId'),
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
          loggerProvider.overrideWithValue(spyTalker),
          currentUserIdProvider.overrideWith(
            (ref) => ref.watch(_testUserIdProvider),
          ),
        ],
      );
    }

    test('addMemo: オフラインの場合、ローカルに保存され isSynced が false になること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('title', 'content', testUserId);

      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.userId).equals(testUserId);
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
          expectedUserId: any(named: 'expectedUserId'),
        ),
      );
    });

    test('addMemo: オンラインの場合、ローカルとリモートに保存され isSynced が true になること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('title', 'content', testUserId);

      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.userId).equals(testUserId);
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
          expectedUserId: testUserId,
        ),
      ).called(1);
    });

    test('addMemo: オンラインでアップロードに失敗した場合、isSynced が false のままになること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      final uploadError = Exception('error');
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
          expectedUserId: any(named: 'expectedUserId'),
        ),
      ).thenThrow(uploadError);

      await repository.addMemo('title', 'content', testUserId);

      final memos = await database.select(database.memos).get();
      check(memos.first.userId).equals(testUserId);
      check(memos.first.isSynced).equals(false);
      check(spyTalker.handleCalls).length.equals(1);
      check(spyTalker.handleCalls.first.exception).equals(uploadError);
      check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      check(
        spyTalker.handleCalls.first.message,
      ).equals('Failed to save data to the server');
    });

    test('updateMemo: オフラインの場合、ローカルが更新され isSynced が false になること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              userId: testUserId,
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(true),
            ),
          );

      await repository.updateMemo(
        'id1',
        'new title',
        'new content',
        testUserId,
      );

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
          expectedUserId: any(named: 'expectedUserId'),
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
              userId: testUserId,
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await repository.updateMemo(
        'id1',
        'new title',
        'new content',
        testUserId,
      );

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
          expectedUserId: testUserId,
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
              userId: testUserId,
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final uploadError = Exception('error');
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
          expectedUserId: any(named: 'expectedUserId'),
        ),
      ).thenThrow(uploadError);

      await repository.updateMemo(
        'id1',
        'new title',
        'new content',
        testUserId,
      );

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.isSynced).equals(false);
      check(spyTalker.handleCalls).length.equals(1);
      check(spyTalker.handleCalls.first.exception).equals(uploadError);
      check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      check(
        spyTalker.handleCalls.first.message,
      ).equals('Failed to update data to the server');
    });

    test('deleteMemo: オフラインの場合、ローカルで論理削除され isSynced が false になること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'id1',
              userId: testUserId,
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(true),
            ),
          );

      await repository.deleteMemo('id1', testUserId);

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
          expectedUserId: any(named: 'expectedUserId'),
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
                userId: testUserId,
                title: 'old',
                content: 'old',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await repository.deleteMemo('id1', testUserId);

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
              userId: testUserId,
              title: 'old',
              content: 'old',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final uploadError = Exception('error');
      when(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
          expectedUserId: any(named: 'expectedUserId'),
        ),
      ).thenThrow(uploadError);

      await repository.deleteMemo('id1', testUserId);

      final memo = await (database.select(
        database.memos,
      )..where((m) => m.id.equals('id1'))).getSingle();
      check(memo.isDeleted).equals(true);
      check(memo.isSynced).equals(false);
      check(spyTalker.handleCalls).length.equals(1);
      check(spyTalker.handleCalls.first.exception).equals(uploadError);
      check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      check(
        spyTalker.handleCalls.first.message,
      ).equals('Failed to delete data on the server');
    });

    test('syncUnsentMemos: 未送信のメモがない場合、何もしないこと', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await repository.syncUnsentMemos(testUserId);
      verifyNever(
        () => mockRemoteService.uploadMemo(
          id: any(named: 'id'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
          expectedUserId: any(named: 'expectedUserId'),
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
              userId: testUserId,
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
              userId: testUserId,
              title: '2',
              content: '2',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(true),
            ),
          );

      await repository.syncUnsentMemos(testUserId);

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
          expectedUserId: testUserId,
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
              userId: testUserId,
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
              userId: testUserId,
              title: '2',
              content: '2',
              createdAt: now,
              updatedAt: now,
              isSynced: const drift.Value(false),
            ),
          );
      final syncError = Exception('error');
      when(
        () => mockRemoteService.uploadMemo(
          id: '1',
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: any(named: 'isDeleted'),
          expectedUserId: any(named: 'expectedUserId'),
        ),
      ).thenThrow(syncError);

      await repository.syncUnsentMemos(testUserId);

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
          expectedUserId: testUserId,
        ),
      ).called(1);
      check(spyTalker.handleCalls).length.equals(1);
      check(spyTalker.handleCalls.first.exception).equals(syncError);
      check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      check(
        spyTalker.handleCalls.first.message,
      ).equals('Failed to sync memo (id: 1) to server');
    });

    test('getAllMemos: オフラインの場合、同期をスキップしローカルの未削除メモを返すこと', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: '1',
              userId: testUserId,
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
              userId: testUserId,
              title: '2',
              content: '2',
              createdAt: now,
              updatedAt: now,
              isDeleted: const drift.Value(true),
            ),
          );

      final memos = await repository.getAllMemos(testUserId);

      check(memos.length).equals(1);
      check(memos.first.id).equals('1');
      check(memos.first.userId).equals(testUserId);
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

      final memos = await repository.getAllMemos(testUserId);

      check(memos.length).equals(1);
      check(memos.first.id).equals('remote1');
      check(memos.first.userId).equals(testUserId);
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
                userId: testUserId,
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

        final memos = await repository.getAllMemos(testUserId);

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
                userId: testUserId,
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

        final memos = await repository.getAllMemos(testUserId);

        check(memos.length).equals(1);
        check(memos.first.title).equals('local');
      },
    );

    test('getAllMemos: fetchMemos で例外が発生した場合、エラーを適切に処理すること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      final fetchError = Exception('fetch error');
      when(() => mockRemoteService.fetchMemos()).thenThrow(fetchError);

      final memos = await repository.getAllMemos(testUserId);

      check(memos.length).equals(0); // local is empty
      check(spyTalker.handleCalls).length.equals(1);
      check(spyTalker.handleCalls.first.exception).equals(fetchError);
      check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      check(
        spyTalker.handleCalls.first.message,
      ).equals('Failed to fetch data from the server');
    });

    test(
      'getAllMemos: syncUnsent が false の場合、未送信メモの送信（uploadMemo）をスキップすること',
      () async {
        final container = createContainer();
        final repository = container.read(memoRepositoryProvider);

        // 未送信のローカルメモを直接挿入（isSynced = false）
        await database
            .into(database.memos)
            .insert(
              MemosCompanion.insert(
                id: 'unsent-memo-1',
                userId: testUserId,
                title: '未送信メモ',
                content: '内容',
                createdAt: now,
                updatedAt: now,
                isSynced: const drift.Value(false),
              ),
            );

        // getAllMemos(syncUnsent: false) を呼び出し
        await repository.getAllMemos(testUserId, syncUnsent: false);

        // uploadMemo は一度も呼ばれないこと（未送信メモの送信がスキップされたこと）
        verifyNever(
          () => mockRemoteService.uploadMemo(
            id: any(named: 'id'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: any(named: 'isDeleted'),
            expectedUserId: any(named: 'expectedUserId'),
          ),
        );
        // リモートからの取得自体は行われること
        verify(() => mockRemoteService.fetchMemos()).called(1);
      },
    );

    test('getLocalMemos: オンラインでもリモート取得を行わずローカルの未削除メモのみを返すこと', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'local-1',
              userId: testUserId,
              title: 'Local 1',
              content: 'Content 1',
              createdAt: now,
              updatedAt: now,
              isDeleted: const drift.Value(false),
            ),
          );
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'local-deleted',
              userId: testUserId,
              title: 'Deleted',
              content: 'Deleted Content',
              createdAt: now,
              updatedAt: now,
              isDeleted: const drift.Value(true),
            ),
          );
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'other-user-memo',
              userId: 'other_user',
              title: 'Other',
              content: 'Other Content',
              createdAt: now,
              updatedAt: now,
              isDeleted: const drift.Value(false),
            ),
          );

      final memos = await repository.getLocalMemos(testUserId);

      check(memos.length).equals(1);
      check(memos.first.id).equals('local-1');
      check(memos.first.userId).equals(testUserId);
      verifyNever(() => mockRemoteService.fetchMemos());
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
      final subscription = repository
          .watchAllMemos(testUserId)
          .listen(emissions.add);

      // 1. 初期状態（空リスト）のイベントが届くのを待つ
      await Future<void>.delayed(const Duration(milliseconds: 10));
      check(emissions.length).equals(1);
      check(emissions.first).isEmpty();

      // 2. 1つ目のメモを追加
      await repository.addMemo('watch1', 'content1', testUserId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      check(emissions.length).equals(2);
      check(emissions[1].length).equals(1);
      check(emissions[1][0].title).equals('watch1');

      // 3. 2つ目のメモを追加
      await repository.addMemo('watch2', 'content2', testUserId);
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

    test(
      'watchFilteredMemos: 指定した条件（クエリ・カテゴリ・未同期）で絞り込まれたメモを Stream で取得できること',
      () async {
        final container = createContainer(isOnline: false);
        final repository = container.read(memoRepositoryProvider);

        // テストデータの準備（オフライン保存のため isSynced は false）
        await repository.addMemo(
          '買物リスト',
          '牛乳を買う',
          testUserId,
          category: MemoCategory.personal,
        );
        await repository.addMemo(
          '仕事のタスク',
          '資料作成',
          testUserId,
          category: MemoCategory.work,
        );

        // 1. クエリ（部分一致）絞り込みの検証
        final queryEmissions = <List<MemoModel>>[];
        final querySub = repository
            .watchFilteredMemos(testUserId, query: '買物')
            .listen(queryEmissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        check(queryEmissions.last.length).equals(1);
        check(queryEmissions.last.first.title).equals('買物リスト');
        await querySub.cancel();

        // 2. カテゴリ絞り込みの検証
        final categoryEmissions = <List<MemoModel>>[];
        final categorySub = repository
            .watchFilteredMemos(testUserId, category: MemoCategory.work)
            .listen(categoryEmissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        check(categoryEmissions.last.length).equals(1);
        check(categoryEmissions.last.first.title).equals('仕事のタスク');
        await categorySub.cancel();

        // 3. 未同期（unsyncedOnly: true）絞り込みの検証
        final unsyncedEmissions = <List<MemoModel>>[];
        final unsyncedSub = repository
            .watchFilteredMemos(testUserId, unsyncedOnly: true)
            .listen(unsyncedEmissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        check(unsyncedEmissions.last.length).equals(2);
        await unsyncedSub.cancel();
      },
    );

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

      await repository.fetchAndMergeRemoteMemos(testUserId);

      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.id).equals('remote_fetch');
      check(memos.first.userId).equals(testUserId);
      check(memos.first.title).equals('fetch_title');
    });

    test('fetchAndMergeRemoteMemos: リモート更新マージ時に既存のローカルカテゴリが維持されること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      // 事前にローカルにカテゴリ付きメモを作成
      await repository.addMemo(
        '既存タイトル',
        '既存本文',
        testUserId,
        category: MemoCategory.work,
      );
      final localMemos = await database.select(database.memos).get();
      final memoId = localMemos.first.id;

      // リモートから更新（より新しい updatedAt）を受信
      final remoteUpdatedAt = now.add(const Duration(minutes: 5));
      when(() => mockRemoteService.fetchMemos()).thenAnswer(
        (_) async => [
          {
            'id': memoId,
            'title': 'リモート更新タイトル',
            'content': 'リモート更新本文',
            'createdAt': now,
            'updatedAt': remoteUpdatedAt,
            'isDeleted': false,
          },
        ],
      );

      await repository.fetchAndMergeRemoteMemos(testUserId);

      final mergedMemos = await database.select(database.memos).get();
      check(mergedMemos.length).equals(1);
      check(mergedMemos.first.id).equals(memoId);
      check(mergedMemos.first.title).equals('リモート更新タイトル');
      // ローカルで設定していたカテゴリが保持されていること
      check(mergedMemos.first.category).equals(MemoCategory.work);
    });

    test('fetchAndMergeRemoteMemos: '
        '既存メモがある場合、リモート新規メモは重複せず先頭になるsortOrderが割り当てられること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      // 事前にローカルにメモを作成（sortOrder: 0）
      await repository.addMemo('既存メモ', '既存内容', testUserId);
      final initialLocalMemos = await database.select(database.memos).get();
      check(initialLocalMemos.first.sortOrder).equals(0);

      // リモートから新規メモが2件届く
      when(() => mockRemoteService.fetchMemos()).thenAnswer(
        (_) async => [
          {
            'id': 'remote_new_1',
            'title': 'リモート新規1',
            'content': '本文1',
            'createdAt': now.add(const Duration(minutes: 1)),
            'updatedAt': now.add(const Duration(minutes: 1)),
            'isDeleted': false,
          },
          {
            'id': 'remote_new_2',
            'title': 'リモート新規2',
            'content': '本文2',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
        ],
      );

      await repository.fetchAndMergeRemoteMemos(testUserId);

      final mergedMemos = await database.select(database.memos).get();
      check(mergedMemos.length).equals(3);

      final newMemo1 = mergedMemos.firstWhere((m) => m.id == 'remote_new_1');
      final newMemo2 = mergedMemos.firstWhere((m) => m.id == 'remote_new_2');
      final existingMemo = mergedMemos.firstWhere(
        (m) => m.id == initialLocalMemos.first.id,
      );

      // 既存メモは新規件数分シフトされ、新規メモは0, 1に配置されること
      check(existingMemo.sortOrder).equals(2);
      check(newMemo1.sortOrder).equals(0);
      check(newMemo2.sortOrder).equals(1);
    });

    test('マルチユーザー分離: 異なるユーザーIDのメモは互いに取得・更新・削除されないこと', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      // ユーザーA（testUserId）とユーザーB（otherUserId）のメモを追加
      await repository.addMemo('User A Memo', 'Content A', testUserId);
      await repository.addMemo('User B Memo', 'Content B', otherUserId);

      // ユーザーAで取得するとユーザーAのメモのみ返る
      final userAMemos = await repository.getAllMemos(testUserId);
      check(userAMemos.length).equals(1);
      check(userAMemos.first.title).equals('User A Memo');
      check(userAMemos.first.userId).equals(testUserId);

      // ユーザーBで取得するとユーザーBのメモのみ返る
      final userBMemos = await repository.getAllMemos(otherUserId);
      check(userBMemos.length).equals(1);
      check(userBMemos.first.title).equals('User B Memo');
      check(userBMemos.first.userId).equals(otherUserId);

      // ユーザーAがユーザーBのメモIDを指定して更新しようとしても変更されない
      await repository.updateMemo(
        userBMemos.first.id,
        'Hacked Title',
        'Hacked Content',
        testUserId,
      );
      final userBMemosAfterUpdate = await repository.getAllMemos(otherUserId);
      check(userBMemosAfterUpdate.first.title).equals('User B Memo');

      // ユーザーAがユーザーBのメモIDを指定して削除しようとしても削除されない
      await repository.deleteMemo(userBMemos.first.id, testUserId);
      final userBMemosAfterDelete = await repository.getAllMemos(otherUserId);
      check(userBMemosAfterDelete.length).equals(1);
    });

    test('addMemo: 先頭（sortOrder: 0）に追加され、既存メモが後ろにシフトされること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('1つ目のメモ', '内容1', testUserId);
      await repository.addMemo('2つ目のメモ', '内容2', testUserId);

      final memos = await repository.getAllMemos(testUserId);
      check(memos.length).equals(2);

      final secondAdded = memos.firstWhere((m) => m.title == '2つ目のメモ');
      final firstAdded = memos.firstWhere((m) => m.title == '1つ目のメモ');

      // 2つ目（最新）が0、1つ目が1にシフトされていること
      check(secondAdded.sortOrder).equals(0);
      check(firstAdded.sortOrder).equals(1);
    });

    test('fetchAndMergeRemoteMemos後にaddMemoを実行した際、'
        '新規ローカルメモが先頭（0）になり既存メモがシフトされ重複しないこと', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      // 1. リモートからメモを2件取り込む（sortOrder: 0, 1）
      when(() => mockRemoteService.fetchMemos()).thenAnswer(
        (_) async => [
          {
            'id': 'remote_1',
            'title': 'リモート1',
            'content': '内容1',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
          {
            'id': 'remote_2',
            'title': 'リモート2',
            'content': '内容2',
            'createdAt': now.add(const Duration(minutes: 1)),
            'updatedAt': now.add(const Duration(minutes: 1)),
            'isDeleted': false,
          },
        ],
      );

      await repository.fetchAndMergeRemoteMemos(testUserId);
      final remoteMemos = await database.select(database.memos).get();
      check(remoteMemos.length).equals(2);

      // 2. その後、ローカルで新規メモを追加
      await repository.addMemo('ローカルメモ', 'ローカル内容', testUserId);

      final allMemos = await database.select(database.memos).get();
      check(allMemos.length).equals(3);

      final localMemo = allMemos.firstWhere((m) => m.title == 'ローカルメモ');
      final remote1 = allMemos.firstWhere((m) => m.id == 'remote_1');
      final remote2 = allMemos.firstWhere((m) => m.id == 'remote_2');

      // 新規ローカルメモが先頭（0）であり、リモートメモが1, 2にシフトされること
      check(localMemo.sortOrder).equals(0);
      check(remote1.sortOrder).equals(1);
      check(remote2.sortOrder).equals(2);

      // すべてのメモのsortOrderが一意（重複なし）であること
      final sortOrders = allMemos.map((m) => m.sortOrder).toSet();
      check(sortOrders.length).equals(3);
    });

    test('updateSortOrders: 渡されたID順にsortOrderが一括更新されること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('A', 'CA', testUserId);
      await repository.addMemo('B', 'CB', testUserId);

      final memos = await repository.getAllMemos(testUserId);
      final idB = memos.firstWhere((m) => m.title == 'B').id;
      final idA = memos.firstWhere((m) => m.title == 'A').id;

      // 順序を反転（Aを先頭、Bを2番目）
      await repository.updateSortOrders([idA, idB], testUserId);

      final reordered = await repository.getAllMemos(testUserId);
      check(reordered.firstWhere((m) => m.id == idA).sortOrder).equals(0);
      check(reordered.firstWhere((m) => m.id == idB).sortOrder).equals(1);
    });

    test('restoreMemo: オフライン時、論理削除されたメモがisDeleted=falseに復元されること', () async {
      final container = createContainer(isOnline: false);
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('削除予定', '内容', testUserId);
      final memos = await repository.getAllMemos(testUserId);
      final memoId = memos.first.id;

      await repository.deleteMemo(memoId, testUserId);
      check((await repository.getAllMemos(testUserId)).isEmpty).isTrue();

      await repository.restoreMemo(memoId, testUserId);
      final restoredMemos = await repository.getAllMemos(testUserId);
      check(restoredMemos.length).equals(1);
      check(restoredMemos.first.id).equals(memoId);
      check(restoredMemos.first.isDeleted).isFalse();
      check(restoredMemos.first.isSynced).isFalse();
    });

    test('restoreMemo: オンライン時、サーバーに復元が送信されisSynced=trueになること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('復元オンライン', '内容', testUserId);
      final memos = await repository.getAllMemos(testUserId);
      final memoId = memos.first.id;

      await repository.deleteMemo(memoId, testUserId);
      await repository.restoreMemo(memoId, testUserId);

      final restored = (await repository.getAllMemos(testUserId)).first;
      check(restored.isSynced).isTrue();
      verify(
        () => mockRemoteService.uploadMemo(
          id: memoId,
          title: '復元オンライン',
          content: '内容',
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: false,
          expectedUserId: testUserId,
        ),
      ).called(2); // addMemo時とrestoreMemo時
    });

    test('restoreMemo: オンライン時、サーバー同期が例外を投げた場合にTalkerで捕捉されること', () async {
      final container = createContainer();
      final repository = container.read(memoRepositoryProvider);

      await repository.addMemo('エラーテスト', '内容', testUserId);
      final memos = await repository.getAllMemos(testUserId);
      final memoId = memos.first.id;

      await repository.deleteMemo(memoId, testUserId);

      when(
        () => mockRemoteService.uploadMemo(
          id: memoId,
          title: any(named: 'title'),
          content: any(named: 'content'),
          createdAt: any(named: 'createdAt'),
          updatedAt: any(named: 'updatedAt'),
          isDeleted: false,
          expectedUserId: testUserId,
        ),
      ).thenThrow(Exception('Server error on restore'));

      await repository.restoreMemo(memoId, testUserId);

      // ローカルでは復元されているがisSyncedはfalse
      final restored = (await repository.getAllMemos(
        testUserId,
        syncUnsent: false,
      )).first;
      check(restored.isDeleted).isFalse();
      check(restored.isSynced).isFalse();
      check(spyTalker.handleCalls.length).equals(1);
      check(
        spyTalker.handleCalls.first.message,
      ).equals('Failed to restore data on the server');
    });

    group('deleteMemo / restoreMemo のバックグラウンド同期と順序保証', () {
      test('waitForRemoteSync=false時はローカル削除完了後に即返却され、'
          '削除通信中にrestoreMemoしても削除→復元の順で送信されisSyncedが正しく保たれること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final repository = container.read(memoRepositoryProvider);

        await repository.addMemo('順序テスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        final deleteUploadCompleter = Completer<void>();
        final restoreUploadCompleter = Completer<void>();
        final uploadSequence = <bool>[];

        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) {
          uploadSequence.add(true);
          return deleteUploadCompleter.future;
        });
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) {
          uploadSequence.add(false);
          return restoreUploadCompleter.future;
        });

        // リモート通信完了を待たずにローカル削除の完了時点で戻る
        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);

        var current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isTrue();
        check(current.isSynced).isFalse();
        check(uploadSequence).deepEquals([true]);

        // 削除通信が未完了のまま Undo 復元を実行
        await repository.restoreMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);

        current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isFalse();
        check(current.isSynced).isFalse();
        // 先行する削除通信が完了するまで、復元通信はまだ開始されない
        check(uploadSequence).deepEquals([true]);

        // 削除通信が完了しても後続の復元トークンがあるため isSynced は true にならない
        deleteUploadCompleter.complete();
        await Future<void>.delayed(Duration.zero);

        check(uploadSequence).deepEquals([true, false]);
        current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isSynced).isFalse();

        // 復元通信が完了した時点で初めて isSynced=true になる
        restoreUploadCompleter.complete();
        await Future<void>.delayed(Duration.zero);

        current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isFalse();
        check(current.isSynced).isTrue();
      });

      test('削除通信が失敗しても、後続のrestoreMemoの通信は遮断されず実行されること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final repository = container.read(memoRepositoryProvider);

        await repository.addMemo('失敗継続テスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        final deleteUploadCompleter = Completer<void>();
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) => deleteUploadCompleter.future);

        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await repository.restoreMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );

        deleteUploadCompleter.completeError(Exception('delete error'));
        await Future<void>.delayed(Duration.zero);

        final current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isFalse();
        check(current.isSynced).isTrue();
        check(
          spyTalker.handleCalls.first.message,
        ).equals('Failed to delete data on the server');
        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).called(2); // addMemo と restoreMemo
      });

      test(
        'memoRepositoryProviderが再生成されてもmemoSyncQueueProviderにより順序が保証されること',
        () async {
          final container = createContainer();
          addTearDown(container.dispose);
          final repo1 = container.read(memoRepositoryProvider);

          await repo1.addMemo('再生成テスト', '内容', testUserId);
          final memoId = (await repo1.getAllMemos(testUserId)).first.id;

          final deleteCompleter = Completer<void>();
          final uploadSequence = <bool>[];
          when(
            () => mockRemoteService.uploadMemo(
              id: memoId,
              title: any(named: 'title'),
              content: any(named: 'content'),
              createdAt: any(named: 'createdAt'),
              updatedAt: any(named: 'updatedAt'),
              isDeleted: true,
              expectedUserId: testUserId,
            ),
          ).thenAnswer((_) {
            uploadSequence.add(true);
            return deleteCompleter.future;
          });
          when(
            () => mockRemoteService.uploadMemo(
              id: memoId,
              title: any(named: 'title'),
              content: any(named: 'content'),
              createdAt: any(named: 'createdAt'),
              updatedAt: any(named: 'updatedAt'),
              isDeleted: false,
              expectedUserId: testUserId,
            ),
          ).thenAnswer((_) async {
            uploadSequence.add(false);
          });

          await repo1.deleteMemo(memoId, testUserId, waitForRemoteSync: false);
          await Future<void>.delayed(Duration.zero);

          // Repository が再生成されて別のインスタンスになっても同一キューが共有される
          container.invalidate(memoRepositoryProvider);
          final repo2 = container.read(memoRepositoryProvider);

          await repo2.restoreMemo(memoId, testUserId, waitForRemoteSync: false);
          await Future<void>.delayed(Duration.zero);

          // まだ削除通信完了前のため復元通信は開始されない
          check(uploadSequence).deepEquals([true]);

          deleteCompleter.complete();
          await Future<void>.delayed(Duration.zero);
          check(uploadSequence).deepEquals([true, false]);
        },
      );

      test('削除通信中にsyncUnsentMemosとrestoreMemoを行い復元通信が失敗した場合、'
          '古い削除状態は送信されずisSynced=falseのまま維持されること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final repository = container.read(memoRepositoryProvider);

        await repository.addMemo('手動同期競合テスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        final deleteCompleter = Completer<void>();
        final uploadSequence = <bool>[];
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) {
          uploadSequence.add(true);
          return deleteCompleter.future;
        });

        // 削除通信を開始（HTTP待機中）
        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);
        check(uploadSequence).deepEquals([true]);

        // 削除通信の待機中に手動同期を開始（キューで待機する）
        final syncFuture = repository.syncUnsentMemos(testUserId);
        await Future<void>.delayed(Duration.zero);
        check(uploadSequence).deepEquals([true]);

        // その後 Undo を行い、復元通信は失敗するよう設定する
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) async {
          uploadSequence.add(false);
          throw Exception('restore error');
        });
        await repository.restoreMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);
        check(uploadSequence).deepEquals([true]);

        // 先行する削除通信が完了したあと、古い削除状態の再送は起きないこと
        deleteCompleter.complete();
        await syncFuture;
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).called(1);

        final current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isFalse();
        check(current.isSynced).isFalse();
      });

      test('syncUnsentMemosの削除状態送信中にrestoreMemoを実行し、'
          '手動同期成功・復元通信失敗となった場合もisSynced=falseが保たれ再送できること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final repository = container.read(memoRepositoryProvider);

        await database.memosDao.insertMemo(
          MemosCompanion.insert(
            id: 'unsent-del-1',
            userId: testUserId,
            title: '未送信削除メモ',
            content: '内容',
            createdAt: now,
            updatedAt: now,
            isDeleted: const drift.Value(true),
            isSynced: const drift.Value(false),
          ),
        );

        final syncCompleter = Completer<void>();
        when(
          () => mockRemoteService.uploadMemo(
            id: 'unsent-del-1',
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) => syncCompleter.future);

        when(
          () => mockRemoteService.uploadMemo(
            id: 'unsent-del-1',
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).thenThrow(Exception('restore error'));

        // 手動同期で isDeleted=true を送信開始（待機中）
        final syncFuture = repository.syncUnsentMemos(testUserId);
        await Future<void>.delayed(Duration.zero);

        // 送信待機中に Undo 復元を実行
        await repository.restoreMemo(
          'unsent-del-1',
          testUserId,
          waitForRemoteSync: false,
        );

        // 手動同期（古い削除状態）が成功し、続く復元通信は失敗する
        syncCompleter.complete();
        await syncFuture;
        await Future<void>.delayed(Duration.zero);

        // 古い削除状態の送信成功で isSynced=true に上書きされていないこと
        var current = await database.memosDao.getMemoById(
          'unsent-del-1',
          testUserId,
        );
        check(current.isDeleted).isFalse();
        check(current.isSynced).isFalse();

        // 次回の手動同期が成功すれば未同期のまま残っていた復元状態を再送できること
        when(
          () => mockRemoteService.uploadMemo(
            id: 'unsent-del-1',
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) async {});
        await repository.syncUnsentMemos(testUserId);

        current = await database.memosDao.getMemoById(
          'unsent-del-1',
          testUserId,
        );
        check(current.isDeleted).isFalse();
        check(current.isSynced).isTrue();
      });

      test('削除通信待機中にsyncUnsentMemosが呼ばれても、先行削除が成功した場合は重複送信をスキップすること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final repository = container.read(memoRepositoryProvider);

        await repository.addMemo('重複スキップテスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        final deleteCompleter = Completer<void>();
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) => deleteCompleter.future);

        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);

        final syncFuture = repository.syncUnsentMemos(testUserId);
        await Future<void>.delayed(Duration.zero);

        deleteCompleter.complete();
        await syncFuture;

        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).called(1);
        final current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isTrue();
        check(current.isSynced).isTrue();
      });

      test('削除通信待機中に別ユーザーへ切り替わった場合、後続のrestoreMemoタスクは送信されず'
          'isSynced=falseのまま保たれ本人再ログイン後に再送できること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final repository = container.read(memoRepositoryProvider);

        await repository.addMemo('切替テスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        final deleteCompleter = Completer<void>();
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) => deleteCompleter.future);

        // 削除通信を開始（HTTP待機中）
        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);

        // 削除通信待機中に Undo 復元をキューへ登録
        await repository.restoreMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );

        // ログアウト → 別ユーザーへ切り替え
        container.read(_testUserIdProvider.notifier).userId = null;
        container.read(_testUserIdProvider.notifier).userId = otherUserId;
        // 再構築後も同一キュー・最新認証状態が参照されること
        container.invalidate(memoRepositoryProvider);

        // 先行していた削除通信が完了する
        deleteCompleter.complete();
        await Future<void>.delayed(Duration.zero);

        // addMemo 時の 1 回以外、別ユーザー権限での restore 送信は行われていないこと
        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).called(1);

        // 別ユーザー切り替え中に通信が行われず、isSynced=false のまま保たれていること
        var current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isFalse();
        check(current.isSynced).isFalse();

        // 元のユーザーが再ログインして手動同期すると安全に再送されること
        container.read(_testUserIdProvider.notifier).userId = testUserId;
        await container
            .read(memoRepositoryProvider)
            .syncUnsentMemos(testUserId);

        current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isFalse();
        check(current.isSynced).isTrue();
        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).called(1);
      });

      test('キュー待機中にProviderContainerが破棄されても破棄済みRef例外を起こさず'
          '後続の削除リモート送信を省略すること', () async {
        final container = createContainer();
        final repository = container.read(memoRepositoryProvider);

        await repository.addMemo('破棄テスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        final firstDeleteCompleter = Completer<void>();
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) => firstDeleteCompleter.future);

        // 1つ目の削除通信を待機中にする
        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);

        // 復元後に再削除をキューへ積み、後続削除タスクがキュー待ちになる状態を作る
        final restoreCompleter = Completer<void>();
        when(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).thenAnswer((_) => restoreCompleter.future);

        await repository.restoreMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );

        // 先行タスクをエラーで終わらせる前にコンテナを破棄（!ref.mounted）
        container.dispose();
        firstDeleteCompleter.complete();
        restoreCompleter.complete();
        await Future<void>.delayed(Duration.zero);

        // 破棄後は後続の restore / delete 送信が呼ばれないこと
        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: testUserId,
          ),
        ).called(1);
        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).called(1); // addMemo 時の 1 回のみ
        final current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isTrue();
        check(current.isSynced).isFalse();
      });

      test('DB取得中（getMemoById）に別ユーザーへ切り替わった場合、'
          'deleteMemoのリモート送信を省略してisSynced=falseを保ち本人再ログイン後に再送できること', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final dbCompleter = Completer<void>();
        var shouldDelayDb = false;
        final hookedDao = _HookedMemosDao(
          database,
          onBeforeGetMemoById: () async {
            if (shouldDelayDb) {
              await dbCompleter.future;
            }
          },
        );
        final repository = MemoRepository(
          dao: hookedDao,
          remote: mockRemoteService,
          clock: container.read(clockProvider),
          talker: spyTalker,
          isOnline: true,
          uuid: container.read(uuidProvider),
          syncQueue: container.read(memoSyncQueueProvider),
          currentUserId: container.read(memoAuthUserIdReaderProvider),
        );

        await repository.addMemo('DB待機削除テスト', '内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        shouldDelayDb = true;
        final deleteFuture = repository.deleteMemo(
          memoId,
          testUserId,
          waitForRemoteSync: false,
        );
        await Future<void>.delayed(Duration.zero);

        // getMemoById 待機中に別ユーザーへ切り替える
        container.read(_testUserIdProvider.notifier).userId = otherUserId;
        dbCompleter.complete();
        await deleteFuture;
        await Future<void>.delayed(Duration.zero);

        verifyNever(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: true,
            expectedUserId: any(named: 'expectedUserId'),
          ),
        );
        var current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isTrue();
        check(current.isSynced).isFalse();

        // 元のユーザーが再ログインして同期すれば安全に再送される
        shouldDelayDb = false;
        container.read(_testUserIdProvider.notifier).userId = testUserId;
        await repository.syncUnsentMemos(testUserId);

        current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isSynced).isTrue();
      });

      test('DB取得中（getMemosByIds）に別ユーザーへ切り替わった場合、'
          'syncUnsentMemosのリモート送信を省略してisSynced=falseを保つこと', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final dbCompleter = Completer<void>();
        final hookedDao = _HookedMemosDao(
          database,
          onBeforeGetMemosByIds: () => dbCompleter.future,
        );
        final repository = MemoRepository(
          dao: hookedDao,
          remote: mockRemoteService,
          clock: container.read(clockProvider),
          talker: spyTalker,
          isOnline: true,
          uuid: container.read(uuidProvider),
          syncQueue: container.read(memoSyncQueueProvider),
          currentUserId: container.read(memoAuthUserIdReaderProvider),
        );

        await database.memosDao.insertMemo(
          MemosCompanion.insert(
            id: 'unsent-db-switch',
            userId: testUserId,
            title: '未送信',
            content: '内容',
            createdAt: now,
            updatedAt: now,
            isSynced: const drift.Value(false),
          ),
        );

        final syncFuture = repository.syncUnsentMemos(testUserId);
        await Future<void>.delayed(Duration.zero);

        // getMemosByIds 待機中に別ユーザーへ切り替える
        container.read(_testUserIdProvider.notifier).userId = otherUserId;
        dbCompleter.complete();
        await syncFuture;

        verifyNever(
          () => mockRemoteService.uploadMemo(
            id: 'unsent-db-switch',
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: any(named: 'isDeleted'),
            expectedUserId: any(named: 'expectedUserId'),
          ),
        );
        final current = await database.memosDao.getMemoById(
          'unsent-db-switch',
          testUserId,
        );
        check(current.isSynced).isFalse();
      });

      test('DB取得中（getMemoById）に別ユーザーへ切り替わった場合、'
          'updateMemoのリモート送信を省略してisSynced=falseを保つこと', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final dbCompleter = Completer<void>();
        var shouldDelayDb = false;
        final hookedDao = _HookedMemosDao(
          database,
          onBeforeGetMemoById: () async {
            if (shouldDelayDb) {
              await dbCompleter.future;
            }
          },
        );
        final repository = MemoRepository(
          dao: hookedDao,
          remote: mockRemoteService,
          clock: container.read(clockProvider),
          talker: spyTalker,
          isOnline: true,
          uuid: container.read(uuidProvider),
          syncQueue: container.read(memoSyncQueueProvider),
          currentUserId: container.read(memoAuthUserIdReaderProvider),
        );

        await repository.addMemo('更新DBテスト', '旧内容', testUserId);
        final memoId = (await repository.getAllMemos(testUserId)).first.id;

        shouldDelayDb = true;
        final updateFuture = repository.updateMemo(
          memoId,
          '新タイトル',
          '新内容',
          testUserId,
        );
        await Future<void>.delayed(Duration.zero);

        container.read(_testUserIdProvider.notifier).userId = otherUserId;
        dbCompleter.complete();
        await updateFuture;

        verify(
          () => mockRemoteService.uploadMemo(
            id: memoId,
            title: '更新DBテスト',
            content: '旧内容',
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: false,
            expectedUserId: testUserId,
          ),
        ).called(1); // addMemo のみで updateMemo の送信はされない
        final current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.title).equals('新タイトル');
        check(current.isSynced).isFalse();
      });

      test('認証情報取得前（TokenInterceptor実行直前）に別ユーザーへ切り替わった場合、'
          'HTTP送信を行わずisSynced=falseを保ち本人再ログイン後に送信できること', () async {
        var storageUserId = testUserId;
        var storageToken = 'token-a';
        var switchBeforeTokenInterceptor = false;
        final sentRequests = <(String method, String path, String? auth)>[];

        final mockStorage = MockTokenStorage();
        when(mockStorage.getUserId).thenAnswer((_) async => storageUserId);
        when(mockStorage.getAccessToken).thenAnswer((_) async => storageToken);

        final adapter = _RecordingHttpClientAdapter((options) async {
          sentRequests.add((
            options.method,
            options.path,
            options.headers['Authorization'] as String?,
          ));
          return ResponseBody.fromString('', 200);
        });

        final baseDio = Dio(BaseOptions(baseUrl: 'https://example.com'))
          ..httpClientAdapter = adapter;
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            clockProvider.overrideWithValue(() => now),
            isOnlineProvider.overrideWithValue(true),
            loggerProvider.overrideWithValue(spyTalker),
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(_testUserIdProvider),
            ),
            tokenStorageInternalProvider.overrideWithValue(mockStorage),
            baseDioProvider.overrideWithValue(baseDio),
            tokenRefreshCallbackProvider.overrideWithValue(() async => false),
          ],
        );
        addTearDown(container.dispose);

        final mainDio = Dio(BaseOptions(baseUrl: 'https://example.com'))
          ..httpClientAdapter = adapter
          ..interceptors.addAll([
            InterceptorsWrapper(
              onRequest: (options, handler) {
                if (switchBeforeTokenInterceptor) {
                  // DB取得完了後、TokenInterceptorの認証情報取得直前に別ユーザーへ切り替え
                  container.read(_testUserIdProvider.notifier).userId =
                      otherUserId;
                  storageUserId = otherUserId;
                  storageToken = 'token-b';
                }
                handler.next(options);
              },
            ),
            container.read(tokenInterceptorProvider),
            container.read(dioInterceptorProvider),
          ]);

        final repository = MemoRepository(
          dao: database.memosDao,
          remote: MemoRemoteService(DioApiClient(mainDio)),
          clock: container.read(clockProvider),
          talker: spyTalker,
          isOnline: true,
          uuid: container.read(uuidProvider),
          syncQueue: container.read(memoSyncQueueProvider),
          currentUserId: container.read(memoAuthUserIdReaderProvider),
        );

        await repository.addMemo('認証直前切替', '内容', testUserId);
        final memoId = (await database.memosDao.getAllMemos(
          testUserId,
        )).first.id;
        check(sentRequests.length).equals(1);
        check(sentRequests.single.$3).equals('Bearer token-a');

        switchBeforeTokenInterceptor = true;
        await repository.deleteMemo(memoId, testUserId);

        // TokenInterceptor の getUserId() 確認で拒否されるため、
        // getAccessToken()・追加の HTTP 送信・token-b 参照は一切起きない
        check(sentRequests.length).equals(1);
        verify(mockStorage.getUserId).called(greaterThanOrEqualTo(3));
        verify(mockStorage.getAccessToken).called(1); // addMemo 時のみ
        check(spyTalker.handleCalls).isEmpty();
        var current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isDeleted).isTrue();
        check(current.isSynced).isFalse();

        // 元のユーザー再ログイン後に同期すると Bearer token-a で安全に再送される
        switchBeforeTokenInterceptor = false;
        container.read(_testUserIdProvider.notifier).userId = testUserId;
        storageUserId = testUserId;
        storageToken = 'token-a';
        await repository.syncUnsentMemos(testUserId);

        check(sentRequests.length).equals(2);
        check(
          sentRequests.last,
        ).equals(('PUT', '/memos/$memoId', 'Bearer token-a'));
        current = await database.memosDao.getMemoById(memoId, testUserId);
        check(current.isSynced).isTrue();
      });

      test('同一秒内でサブ秒を含む削除成功・復元失敗の後にmergeRemoteMemosが実行されても、'
          '削除・復元の保存値と送信値が秒精度に揃い未同期の復元が保持・再送されること', () async {
        final createdTime = DateTime(2026, 11, 14, 9, 59, 0, 450);
        final deleteClockTime = DateTime(2026, 11, 14, 10, 0, 0, 200);
        final restoreClockTime = DateTime(2026, 11, 14, 10, 0, 0, 800);
        var currentClock = createdTime;

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            memoRemoteServiceProvider.overrideWithValue(mockRemoteService),
            clockProvider.overrideWithValue(() => currentClock),
            isOnlineProvider.overrideWithValue(true),
            loggerProvider.overrideWithValue(spyTalker),
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(_testUserIdProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        final uploadedRecords =
            <({bool isDeleted, DateTime createdAt, DateTime updatedAt})>[];
        var shouldFailRestore = false;

        when(
          () => mockRemoteService.uploadMemo(
            id: any(named: 'id'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            createdAt: any(named: 'createdAt'),
            updatedAt: any(named: 'updatedAt'),
            isDeleted: any(named: 'isDeleted'),
            expectedUserId: testUserId,
          ),
        ).thenAnswer((invocation) async {
          final isDeleted = invocation.namedArguments[#isDeleted] as bool;
          final uploadedCreatedAt =
              invocation.namedArguments[#createdAt] as DateTime;
          final uploadedUpdatedAt =
              invocation.namedArguments[#updatedAt] as DateTime;
          if (!isDeleted && shouldFailRestore) {
            throw Exception('restore upload failed');
          }
          uploadedRecords.add((
            isDeleted: isDeleted,
            createdAt: uploadedCreatedAt,
            updatedAt: uploadedUpdatedAt,
          ));
        });

        final repository = container.read(memoRepositoryProvider);
        await repository.addMemo('サブ秒テスト', '本文', testUserId);
        final memoId = (await database.memosDao.getAllMemos(
          testUserId,
        )).first.id;

        // 1. 削除をサブ秒（10:00:00.200）で実行し、送信値・DB保存値ともに秒精度に揃うこと
        currentClock = deleteClockTime;
        await repository.deleteMemo(memoId, testUserId);

        final deletedLocal = await database.memosDao.getMemoById(
          memoId,
          testUserId,
        );
        final expectedSecondTime = DateTime(2026, 11, 14, 10);
        check(deletedLocal.updatedAt).equals(expectedSecondTime);
        check(uploadedRecords.last.isDeleted).isTrue();
        check(uploadedRecords.last.updatedAt).equals(expectedSecondTime);

        // 2. 同じ秒（10:00:00.800）で復元を実行し、リモート送信だけ失敗させる
        currentClock = restoreClockTime;
        shouldFailRestore = true;
        await repository.restoreMemo(memoId, testUserId);

        var restoredLocal = await database.memosDao.getMemoById(
          memoId,
          testUserId,
        );
        check(restoredLocal.isDeleted).isFalse();
        check(restoredLocal.isSynced).isFalse();
        check(restoredLocal.updatedAt).equals(expectedSecondTime);

        // 3. リモートが削除時のデータ（サブ秒あり想定も含む）を返しても未同期の復元を維持すること
        when(() => mockRemoteService.fetchMemos()).thenAnswer(
          (_) async => [
            {
              'id': memoId,
              'title': 'サブ秒テスト',
              'content': '本文',
              'createdAt': DateTime(2026, 11, 14, 9, 59),
              'updatedAt': deleteClockTime,
              'isDeleted': true,
            },
          ],
        );

        await repository.fetchAndMergeRemoteMemos(testUserId);

        restoredLocal = await database.memosDao.getMemoById(memoId, testUserId);
        check(restoredLocal.isDeleted).isFalse();
        check(restoredLocal.isSynced).isFalse();
        check(restoredLocal.updatedAt).equals(expectedSecondTime);

        // 4. 通信回復後の同期で未同期の復元が再送され、同期済みになること
        shouldFailRestore = false;
        await repository.syncUnsentMemos(testUserId);

        restoredLocal = await database.memosDao.getMemoById(memoId, testUserId);
        check(restoredLocal.isDeleted).isFalse();
        check(restoredLocal.isSynced).isTrue();
        check(uploadedRecords.last.isDeleted).isFalse();
        check(uploadedRecords.last.updatedAt).equals(expectedSecondTime);
      });
    });
  });
}
