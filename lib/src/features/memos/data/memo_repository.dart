import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_extension.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_sample/src/features/memos/data/memos_dao.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/uuid.dart';

part 'memo_repository.g.dart';

/// メモIDごとの削除・復元リモート同期をFIFO順で直列化するキュー
class MemoSyncQueue {
  final Map<(String, String), Future<void>> _queues = {};
  final Map<(String, String), int> _latestTokens = {};
  var _tokenCounter = 0;

  /// 指定メモに対する新しい変更トークンを発行・記録する
  int nextToken(String userId, String id) {
    final token = ++_tokenCounter;
    _latestTokens[(userId, id)] = token;
    return token;
  }

  /// 指定メモに対する現在の変更トークンを返す（未キュー時は null）
  int? currentToken(String userId, String id) => _latestTokens[(userId, id)];

  /// 同一メモの同期処理を先行タスクの完了後に直列実行する
  Future<void> enqueue(String userId, String id, Future<void> Function() task) {
    final key = (userId, id);
    final previous = _queues[key] ?? Future<void>.value();
    late final Future<void> current;
    current = previous.whenComplete(() async {
      try {
        await task();
      } finally {
        if (identical(_queues[key], current)) {
          unawaited(_queues.remove(key));
          _latestTokens.remove(key);
        }
      }
    });
    _queues[key] = current;
    return current;
  }
}

/// メモ（Memo）のデータをデータベースに保存したり、取り出したりするためのリポジトリ
class MemoRepository {
  /// コンストラクタ
  MemoRepository({
    required MemosDao dao,
    required MemoRemoteService remote,
    required DateTime Function() clock,
    required Talker talker,
    required bool isOnline,
    required Uuid uuid,
    required MemoSyncQueue syncQueue,
    required String? Function() currentUserId,
  }) : _dao = dao,
       _remote = remote,
       _clock = clock,
       _talker = talker,
       _isOnline = isOnline,
       _uuid = uuid,
       _syncQueue = syncQueue,
       _currentUserId = currentUserId;

  final MemosDao _dao;
  final MemoRemoteService _remote;
  final DateTime Function() _clock;
  final Talker _talker;
  final bool _isOnline;
  final Uuid _uuid;
  final MemoSyncQueue _syncQueue;
  final String? Function() _currentUserId;

  /// 新しいメモをデータベースに追加する
  Future<void> addMemo(
    String title,
    String content,
    String userId, {
    MemoCategory? category,
  }) async {
    final now = _clock().truncateToSeconds();

    // UUIDを作る
    final generatedId = _uuid.v4();

    // スマホに保存する（トランザクションで既存のメモをシフトしつつ先頭に挿入）
    await _dao.insertMemoWithShift(
      userId,
      MemosCompanion.insert(
        id: generatedId,
        userId: userId,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        category: drift.Value(category),
        sortOrder: const drift.Value(0),
      ),
    );

    if (_isOnline && _currentUserId() == userId) {
      // オンラインの時はサーバに保存を試みる
      try {
        await _remote.uploadMemo(
          id: generatedId,
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
          expectedUserId: userId,
        );

        if (_currentUserId() == userId) {
          // 保存に成功したら「送信済み (true)」に更新
          await _dao.updateMemo(
            generatedId,
            userId,
            const MemosCompanion(isSynced: drift.Value(true)),
          );
        }

        _talker.debug('The data has been saved to the server.');
      } on Exception catch (e, st) {
        _handleUploadError(e, st, 'Failed to save data to the server');
      }
    }
  }

  /// メモを更新する
  Future<void> updateMemo(
    String id,
    String title,
    String content,
    String userId, {
    drift.Value<MemoCategory?> category = const drift.Value.absent(),
  }) async {
    final now = _clock().truncateToSeconds();

    // まずはスマホ側のデータを更新し、未送信状態に戻す
    await _dao.updateMemo(
      id,
      userId,
      MemosCompanion(
        title: drift.Value(title),
        content: drift.Value(content),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        category: category,
      ),
    );

    if (_isOnline) {
      // オンラインの時はサーバに保存を試みる
      try {
        final memo = await _dao.getMemoById(id, userId);
        if (_currentUserId() != userId) {
          return;
        }
        await _remote.uploadMemo(
          id: id,
          title: title,
          content: content,
          createdAt: memo.createdAt,
          updatedAt: now,
          isDeleted: false,
          expectedUserId: memo.userId,
        );

        if (_currentUserId() == userId) {
          // 保存に成功したら「送信済み (true)」に更新
          await _dao.updateMemo(
            id,
            userId,
            const MemosCompanion(isSynced: drift.Value(true)),
          );
        }

        _talker.debug('The updated data has been saved to the server.');
      } on Exception catch (e, st) {
        _handleUploadError(e, st, 'Failed to update data to the server');
      }
    }
  }

  void _handleUploadError(Exception e, StackTrace st, String errorLog) {
    if (e is DioException &&
        (e.type == DioExceptionType.cancel ||
            e.error == const AppException.cancel())) {
      _talker.debug('$errorLog (cancelled due to auth switch)');
      return;
    }
    _talker.handle(e, st, errorLog);
  }

  /// メモをリモート送信し、送信状態が最新のローカル状態・トークンと一致する場合のみ同期済みに更新する
  Future<void> _uploadMemoAndMarkSyncedIfUnchanged({
    required Memo memo,
    required DateTime updatedAt,
    required bool isDeleted,
    required int? expectedToken,
    required String successLog,
    required String errorLog,
  }) async {
    try {
      await _remote.uploadMemo(
        id: memo.id,
        title: memo.title,
        content: memo.content,
        createdAt: memo.createdAt,
        updatedAt: updatedAt,
        isDeleted: isDeleted,
        expectedUserId: memo.userId,
      );

      // 送信待機中に新しいローカル操作（Undoや編集等）が行われた場合や、
      // 認証ユーザーが切り替わった場合は古い通信結果で isSynced を true に上書きしない
      if (_currentUserId() == memo.userId &&
          _syncQueue.currentToken(memo.userId, memo.id) == expectedToken) {
        await _dao.markAsSyncedIfUnchanged(
          id: memo.id,
          userId: memo.userId,
          title: memo.title,
          content: memo.content,
          createdAt: memo.createdAt,
          updatedAt: updatedAt,
          isDeleted: isDeleted,
        );
      }

      _talker.debug(successLog);
    } on Exception catch (e, st) {
      _handleUploadError(e, st, errorLog);
    }
  }

  /// 現在の認証ユーザーが [userId] と一致する場合のみ、直列キュー上で同期タスクを実行する
  ///
  /// 待機中にログアウトや別ユーザーへの切り替えが発生した場合はリモート送信を省略し、
  /// isSynced = false のまま保つことで他人の認証情報での誤送信を防ぐ。
  Future<void> _enqueueIfAuthenticatedUser(
    String userId,
    String id,
    Future<void> Function() task,
  ) {
    return _syncQueue.enqueue(userId, id, () async {
      if (_currentUserId() != userId) {
        return;
      }
      await task();
    });
  }

  /// 削除・復元のローカル変更に対応するリモート送信を直列キュー経由で実行する
  Future<void> _syncMemoDeletionState({
    required String id,
    required String userId,
    required DateTime updatedAt,
    required bool isDeleted,
    required int token,
    required bool waitForRemoteSync,
    required String successLog,
    required String errorLog,
  }) async {
    if (!_isOnline) {
      return;
    }

    final syncFuture = _enqueueIfAuthenticatedUser(userId, id, () async {
      final memo = await _dao.getMemoById(id, userId);
      if (_currentUserId() != userId) {
        return;
      }
      await _uploadMemoAndMarkSyncedIfUnchanged(
        memo: memo,
        updatedAt: updatedAt,
        isDeleted: isDeleted,
        expectedToken: token,
        successLog: successLog,
        errorLog: errorLog,
      );
    });

    if (waitForRemoteSync) {
      await syncFuture;
    } else {
      unawaited(syncFuture);
    }
  }

  /// メモを削除（論理削除）する
  Future<void> deleteMemo(
    String id,
    String userId, {
    bool waitForRemoteSync = true,
  }) async {
    final now = _clock().truncateToSeconds();

    // スマホ側で論理削除マークをつける
    await _dao.updateMemo(
      id,
      userId,
      MemosCompanion(
        updatedAt: drift.Value(now),
        isDeleted: const drift.Value(true),
        isSynced: const drift.Value(false),
      ),
    );
    final token = _syncQueue.nextToken(userId, id);

    await _syncMemoDeletionState(
      id: id,
      userId: userId,
      updatedAt: now,
      isDeleted: true,
      token: token,
      waitForRemoteSync: waitForRemoteSync,
      successLog: 'The deleted status has been sent to the server.',
      errorLog: 'Failed to delete data on the server',
    );
  }

  /// 削除されたメモを復元（論理削除を解除）する
  Future<void> restoreMemo(
    String id,
    String userId, {
    bool waitForRemoteSync = true,
  }) async {
    final now = _clock().truncateToSeconds();

    // スマホ側で論理削除を解除し、未同期状態に戻す
    await _dao.restoreMemo(id, userId, now);
    final token = _syncQueue.nextToken(userId, id);

    await _syncMemoDeletionState(
      id: id,
      userId: userId,
      updatedAt: now,
      isDeleted: false,
      token: token,
      waitForRemoteSync: waitForRemoteSync,
      successLog: 'The restored status has been sent to the server.',
      errorLog: 'Failed to restore data on the server',
    );
  }

  /// メモの並び順（ドラッグ＆ドロップ後）を一括更新する
  Future<void> updateSortOrders(List<String> orderedIds, String userId) async {
    await _dao.updateSortOrders(orderedIds, userId);
  }

  /// スマホに残っている「未送信のメモ」をまとめてサーバーに送る処理
  Future<void> syncUnsentMemos(String userId) async {
    // スマホの中から isSynced が false のメモを探し出す
    final unsentMemos = await _dao.getUnsyncedMemos(userId);

    if (unsentMemos.isEmpty) {
      return;
    }

    // 見つかった未送信のメモを、メモごとの直列キューを通して順番にサーバーに送る
    for (final memo in unsentMemos) {
      await _enqueueIfAuthenticatedUser(userId, memo.id, () async {
        final latestMemo = (await _dao.getMemosByIds([
          memo.id,
        ], userId)).firstOrNull;
        if (_currentUserId() != userId ||
            latestMemo == null ||
            latestMemo.isSynced) {
          return;
        }

        await _uploadMemoAndMarkSyncedIfUnchanged(
          memo: latestMemo,
          updatedAt: latestMemo.updatedAt,
          isDeleted: latestMemo.isDeleted,
          expectedToken: _syncQueue.currentToken(userId, memo.id),
          successLog: 'Synced unsent memo to server. id: ${memo.id}',
          errorLog: 'Failed to sync memo (id: ${memo.id}) to server',
        );
      });
    }
  }

  /// 保存されているすべてのメモを一覧（リスト）として取得する
  ///
  /// [syncUnsent] が false の場合、未送信ローカルメモの送信を行わずに取得・マージします。
  Future<List<MemoModel>> getAllMemos(
    String userId, {
    bool syncUnsent = true,
  }) async {
    await fetchAndMergeRemoteMemos(userId, syncUnsent: syncUnsent);

    return await getLocalMemos(userId);
  }

  /// ローカルDBから「削除されていない」メモ一覧を取得する（リモート同期は行わない）
  Future<List<MemoModel>> getLocalMemos(String userId) async {
    final driftMemos = await _dao.getAllMemos(userId);
    return driftMemos.map(_mapToMemoModel).toList();
  }

  /// データベースの変更を自動で検知して流し続けるストリーム
  Stream<List<MemoModel>> watchAllMemos(String userId) {
    return _dao.watchAllMemos(userId).map((driftMemos) {
      return driftMemos.map(_mapToMemoModel).toList();
    });
  }

  /// 検索条件やカテゴリ、未同期フラグを指定してメモの変更を監視するストリーム
  Stream<List<MemoModel>> watchFilteredMemos(
    String userId, {
    String? query,
    MemoCategory? category,
    bool? unsyncedOnly,
  }) {
    return _dao
        .watchFilteredMemos(
          userId,
          query: query,
          category: category,
          unsyncedOnly: unsyncedOnly,
        )
        .map((driftMemos) {
          return driftMemos.map(_mapToMemoModel).toList();
        });
  }

  /// DriftのMemoデータをドメイン層のMemoModelへ変換するヘルパーメソッド
  MemoModel _mapToMemoModel(Memo memo) {
    return MemoModel(
      id: memo.id,
      userId: memo.userId,
      title: memo.title,
      content: memo.content,
      createdAt: memo.createdAt,
      updatedAt: memo.updatedAt,
      isDeleted: memo.isDeleted,
      isSynced: memo.isSynced,
      category: memo.category,
      sortOrder: memo.sortOrder,
    );
  }

  /// リモートサーバーからメモを取得し、ローカルデータベースとマージする処理
  ///
  /// [syncUnsent] が false の場合、未送信メモの送信はスキップします。
  Future<void> fetchAndMergeRemoteMemos(
    String userId, {
    bool syncUnsent = true,
  }) async {
    // 未送信のメモがあればサーバーに送る
    if (_isOnline && syncUnsent) {
      await syncUnsentMemos(userId);
    }

    try {
      final remoteData = await _remote.fetchMemos();

      // サーバーから取得したデータを効率的にマージする
      if (remoteData.isNotEmpty) {
        await _dao.mergeRemoteMemos(userId, remoteData);
      }
      _talker.debug('Merged remote memos into local database.');
    } on Exception catch (e, st) {
      _talker.handle(e, st, 'Failed to fetch data from the server');
    }
  }
}

/// [MemoSyncQueue] をアプリ（ProviderContainer）全体で共有するプロバイダー
@Riverpod(keepAlive: true)
MemoSyncQueue memoSyncQueue(Ref ref) => MemoSyncQueue();

/// 現在認証中のユーザーIDを常に最新値として取得する関数プロバイダー
///
/// [memoRepositoryProvider] が破棄・再生成された後も、キュー内の待機タスクが
/// 破棄済み Ref を参照せずに最新の認証ユーザーIDを参照できるよう keepAlive にしています。
@Riverpod(keepAlive: true)
String? Function() memoAuthUserIdReader(Ref ref) {
  return () => ref.mounted ? ref.read(currentUserIdProvider) : null;
}

/// アプリ全体で[MemoRepository]を使えるようにするためのプロバイダー
@riverpod
MemoRepository memoRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final remote = ref.watch(memoRemoteServiceProvider);
  return MemoRepository(
    dao: db.memosDao,
    remote: remote,
    clock: ref.watch(clockProvider),
    talker: ref.watch(loggerProvider),
    isOnline: ref.watch(isOnlineProvider),
    uuid: ref.watch(uuidProvider),
    syncQueue: ref.watch(memoSyncQueueProvider),
    currentUserId: ref.watch(memoAuthUserIdReaderProvider),
  );
}
