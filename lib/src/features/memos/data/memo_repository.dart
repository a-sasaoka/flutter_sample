import 'package:drift/drift.dart' as drift;
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'memo_repository.g.dart';

/// メモ（Memo）のデータをデータベースに保存したり、取り出したりするためのリポジトリ
class MemoRepository {
  /// コンストラクタ
  MemoRepository(this._ref, this._db, this._remote);

  final Ref _ref;

  final AppDatabase _db;

  final MemoRemoteService _remote;

  /// 新しいメモをデータベースに追加する
  Future<void> addMemo(String title, String content) async {
    final now = _ref.read(currentDateTimeProvider);
    final logger = _ref.read(loggerProvider);

    // UUIDを作る
    final generatedId = const Uuid().v4();

    // スマホに保存する（isSynced はデフォルトで false, isDeleted も false）
    await _db
        .into(_db.memos)
        .insert(
          MemosCompanion.insert(
            id: generatedId,
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
          ),
        );

    if (_ref.read(isOnlineProvider)) {
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
        await (_db.update(_db.memos)..where((m) => m.id.equals(generatedId)))
            .write(const MemosCompanion(isSynced: drift.Value(true)));

        logger.debug('The data has been saved to the server.');
      } on Exception catch (e) {
        logger.error('Failed to save data to the server: $e');
      }
    }
  }

  /// メモを更新する
  Future<void> updateMemo(String id, String title, String content) async {
    final now = _ref.read(currentDateTimeProvider);
    final logger = _ref.read(loggerProvider);

    // まずはスマホ側のデータを更新し、未送信状態に戻す
    await (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
      MemosCompanion(
        title: drift.Value(title),
        content: drift.Value(content),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      ),
    );

    if (_ref.read(isOnlineProvider)) {
      // オンラインの時はサーバに保存を試みる
      try {
        final memo = await (_db.select(
          _db.memos,
        )..where((m) => m.id.equals(id))).getSingle();
        await _remote.uploadMemo(
          id: id,
          title: title,
          content: content,
          createdAt: memo.createdAt,
          updatedAt: now,
          isDeleted: false,
        );

        // 保存に成功したら「送信済み (true)」に更新
        await (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
          const MemosCompanion(isSynced: drift.Value(true)),
        );

        logger.debug('The updated data has been saved to the server.');
      } on Exception catch (e) {
        logger.error('Failed to update data to the server: $e');
      }
    }
  }

  /// メモを削除（論理削除）する
  Future<void> deleteMemo(String id) async {
    final now = _ref.read(currentDateTimeProvider);
    final logger = _ref.read(loggerProvider);

    // スマホ側で論理削除マークをつける
    await (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
      MemosCompanion(
        updatedAt: drift.Value(now),
        isDeleted: const drift.Value(true),
        isSynced: const drift.Value(false),
      ),
    );

    if (_ref.read(isOnlineProvider)) {
      // オンラインの時はサーバに保存を試みる
      try {
        final memo = await (_db.select(
          _db.memos,
        )..where((m) => m.id.equals(id))).getSingle();
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
        await (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
          const MemosCompanion(isSynced: drift.Value(true)),
        );

        logger.debug('The deleted status has been sent to the server.');
      } on Exception catch (e) {
        logger.error('Failed to delete data on the server: $e');
      }
    }
  }

  /// スマホに残っている「未送信のメモ」をまとめてサーバーに送る処理
  Future<void> syncUnsentMemos() async {
    final logger = _ref.read(loggerProvider);

    // スマホの中から isSynced が false のメモを探し出す
    final unsentMemos = await (_db.select(
      _db.memos,
    )..where((m) => m.isSynced.equals(false))).get();

    if (unsentMemos.isEmpty) {
      return;
    }

    // 見つかった未送信のメモを、順番にサーバーに送る
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

        // 成功したら「送信済み」に変更する
        await (_db.update(_db.memos)..where((m) => m.id.equals(memo.id))).write(
          const MemosCompanion(isSynced: drift.Value(true)),
        );

        logger.debug('Synced unsent memo to server. id: ${memo.id}');
      } on Exception catch (e) {
        logger.error('Failed to sync memo (id: ${memo.id}) to server: $e');
        break;
      }
    }
  }

  /// 保存されているすべてのメモを一覧（リスト）として取得する
  Future<List<MemoModel>> getAllMemos() async {
    // 未送信のメモがあればサーバーに送る
    if (_ref.read(isOnlineProvider)) {
      await syncUnsentMemos();
    }

    final logger = _ref.read(loggerProvider);
    try {
      final remoteData = await _remote.fetchMemos();

      // サーバーから取得したデータを一つずつ確認し、スマホ（ローカル）のデータと合流（マージ）する
      for (final remoteMemo in remoteData) {
        final id = remoteMemo['id'] as String;
        final title = remoteMemo['title'] as String;
        final content = remoteMemo['content'] as String;
        final createdAt = remoteMemo['createdAt'] as DateTime;
        final updatedAt = remoteMemo['updatedAt'] as DateTime;
        final isDeleted = remoteMemo['isDeleted'] as bool;

        // スマホ側に同じIDのメモがあるか探す
        final localMemo = await (_db.select(
          _db.memos,
        )..where((m) => m.id.equals(id))).getSingleOrNull();

        if (localMemo == null) {
          // スマホにデータがなければ、新しく追加する
          await _db
              .into(_db.memos)
              .insert(
                MemosCompanion.insert(
                  id: id,
                  title: title,
                  content: content,
                  createdAt: createdAt,
                  updatedAt: updatedAt,
                  isDeleted: drift.Value(isDeleted),
                  isSynced: const drift.Value(true),
                ),
              );
        } else {
          // スマホにデータがある場合は「どちらが最後に更新されたか（updatedAt）」を比べる
          if (updatedAt.isAfter(localMemo.updatedAt)) {
            // サーバーのデータの方が新しければ、スマホのデータを上書きする
            await (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
              MemosCompanion(
                title: drift.Value(title),
                content: drift.Value(content),
                updatedAt: drift.Value(updatedAt),
                isDeleted: drift.Value(isDeleted),
                isSynced: const drift.Value(true),
              ),
            );
          }
        }
      }
      logger.debug('Merged remote memos into local database.');
    } on Exception catch (e) {
      logger.error('Failed to fetch data from the server: $e');
    }

    // データベースから「削除されていない」データを取り出す
    final driftMemos = await (_db.select(
      _db.memos,
    )..where((m) => m.isDeleted.equals(false))).get();

    return driftMemos
        .map(
          (memo) => MemoModel(
            id: memo.id,
            title: memo.title,
            content: memo.content,
            createdAt: memo.createdAt,
            updatedAt: memo.updatedAt,
            isDeleted: memo.isDeleted,
            isSynced: memo.isSynced,
          ),
        )
        .toList();
  }
}

/// アプリ全体で[MemoRepository]を使えるようにするためのプロバイダー
@riverpod
MemoRepository memoRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final remote = ref.watch(memoRemoteServiceProvider);
  return MemoRepository(ref, db, remote);
}
