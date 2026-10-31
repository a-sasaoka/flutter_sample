import 'package:drift/drift.dart' as drift;
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_sample/src/features/memos/data/memos_dao.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/uuid.dart';

part 'memo_repository.g.dart';

/// メモ（Memo）のデータをデータベースに保存したり、取り出したりするためのリポジトリ
class MemoRepository {
  /// コンストラクタ
  const MemoRepository({
    required MemosDao dao,
    required MemoRemoteService remote,
    required DateTime Function() clock,
    required Talker talker,
    required bool isOnline,
    required Uuid uuid,
  }) : _dao = dao,
       _remote = remote,
       _clock = clock,
       _talker = talker,
       _isOnline = isOnline,
       _uuid = uuid;

  final MemosDao _dao;
  final MemoRemoteService _remote;
  final DateTime Function() _clock;
  final Talker _talker;
  final bool _isOnline;
  final Uuid _uuid;

  /// 新しいメモをデータベースに追加する
  Future<void> addMemo(
    String title,
    String content,
    String userId, {
    MemoCategory? category,
  }) async {
    final now = _clock();

    // UUIDを作る
    final generatedId = _uuid.v4();

    // スマホに保存する（isSynced はデフォルトで false, isDeleted も false）
    await _dao.insertMemo(
      MemosCompanion.insert(
        id: generatedId,
        userId: userId,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        category: drift.Value(category),
      ),
    );

    if (_isOnline) {
      // オンラインの時はサーバに保存を試みる
      try {
        await _remote.uploadMemo(
          id: generatedId,
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        );

        // 保存に成功したら「送信済み (true)」に更新
        await _dao.updateMemo(
          generatedId,
          userId,
          const MemosCompanion(isSynced: drift.Value(true)),
        );

        _talker.debug('The data has been saved to the server.');
      } on Exception catch (e, st) {
        _talker.handle(e, st, 'Failed to save data to the server');
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
    final now = _clock();

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
        await _remote.uploadMemo(
          id: id,
          title: title,
          content: content,
          createdAt: memo.createdAt,
          updatedAt: now,
          isDeleted: false,
        );

        // 保存に成功したら「送信済み (true)」に更新
        await _dao.updateMemo(
          id,
          userId,
          const MemosCompanion(isSynced: drift.Value(true)),
        );

        _talker.debug('The updated data has been saved to the server.');
      } on Exception catch (e, st) {
        _talker.handle(e, st, 'Failed to update data to the server');
      }
    }
  }

  /// メモを削除（論理削除）する
  Future<void> deleteMemo(String id, String userId) async {
    final now = _clock();

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

    if (_isOnline) {
      // オンラインの時はサーバに保存を試みる
      try {
        final memo = await _dao.getMemoById(id, userId);
        // サーバーにも「削除済み」として送る
        await _remote.uploadMemo(
          id: id,
          title: memo.title,
          content: memo.content,
          createdAt: memo.createdAt,
          updatedAt: now,
          isDeleted: true,
        );

        // 保存に成功したら「送信済み (true)」に更新
        await _dao.updateMemo(
          id,
          userId,
          const MemosCompanion(isSynced: drift.Value(true)),
        );

        _talker.debug('The deleted status has been sent to the server.');
      } on Exception catch (e, st) {
        _talker.handle(e, st, 'Failed to delete data on the server');
      }
    }
  }

  /// スマホに残っている「未送信のメモ」をまとめてサーバーに送る処理
  Future<void> syncUnsentMemos(String userId) async {
    // スマホの中から isSynced が false のメモを探し出す
    final unsentMemos = await _dao.getUnsyncedMemos(userId);

    if (unsentMemos.isEmpty) {
      return;
    }

    // 見つかった未送信のメモを、順番にサーバーに送る
    final syncedIds = <String>[];
    for (final memo in unsentMemos) {
      try {
        await _remote.uploadMemo(
          id: memo.id,
          title: memo.title,
          content: memo.content,
          createdAt: memo.createdAt,
          updatedAt: memo.updatedAt,
          isDeleted: memo.isDeleted,
        );
        syncedIds.add(memo.id);
        _talker.debug('Synced unsent memo to server. id: ${memo.id}');
      } on Exception catch (e, st) {
        _talker.handle(e, st, 'Failed to sync memo (id: ${memo.id}) to server');
      }
    }

    // 成功したものをまとめてDB更新
    if (syncedIds.isNotEmpty) {
      await _dao.updateSyncStatus(syncedIds, userId, isSynced: true);
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

    // データベースから「削除されていない」データを取り出す
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
        final ids = remoteData.map((e) => e['id'] as String).toList();
        final localMemos = await _dao.getMemosByIds(ids, userId);
        final localMemosMap = {for (final m in localMemos) m.id: m};
        final companionsToUpsert = <MemosCompanion>[];

        for (final remoteMemo in remoteData) {
          if (remoteMemo case {
            'id': final String id,
            'title': final String title,
            'content': final String content,
            'createdAt': final DateTime createdAt,
            'updatedAt': final DateTime updatedAt,
            'isDeleted': final bool isDeleted,
          }) {
            final localMemo = localMemosMap[id];

            // サーバーのデータが新しい場合、またはローカルに存在しない場合に更新/挿入対象とする
            if (localMemo == null || updatedAt.isAfter(localMemo.updatedAt)) {
              companionsToUpsert.add(
                MemosCompanion.insert(
                  id: id,
                  userId: userId,
                  title: title,
                  content: content,
                  createdAt: createdAt,
                  updatedAt: updatedAt,
                  isDeleted: drift.Value(isDeleted),
                  isSynced: const drift.Value(true),
                ),
              );
            }
          }
        }

        if (companionsToUpsert.isNotEmpty) {
          await _dao.upsertMemos(companionsToUpsert);
        }
      }
      _talker.debug('Merged remote memos into local database.');
    } on Exception catch (e, st) {
      _talker.handle(e, st, 'Failed to fetch data from the server');
    }
  }
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
  );
}
