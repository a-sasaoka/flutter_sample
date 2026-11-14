import 'dart:async';

import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_filter_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:flutter_sample/src/features/memos/application/memo_filter_notifier.dart';

part 'memo_notifier.g.dart';

/// メモ一覧のデータ（状態）を管理するためのクラス
@riverpod
class MemoNotifier extends _$MemoNotifier {
  bool _hasSyncedOnInitialOnline = false;
  List<MemoModel>? _lastConfirmedMemos;
  int _activeReorderCount = 0;
  int _authGeneration = 0;

  void _resetSessionState() {
    _hasSyncedOnInitialOnline = false;
    _lastConfirmedMemos = null;
    _activeReorderCount = 0;
  }

  @override
  Stream<List<MemoModel>> build() {
    // 認証ユーザーの変化（ログアウト・再ログイン・アカウント切り替え）を検知し、
    // 世代番号を進めて古い非同期処理の結果を破棄できるようにする
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        _authGeneration++;
        _resetSessionState();
      }
    });

    final userId = ref.watch(currentUserIdProvider);

    // 未ログイン時は空リストを返し、初期同期フラグもリセット
    if (userId == null) {
      _resetSessionState();
      return Stream.value([]);
    }

    final repository = ref.watch(memoRepositoryProvider);

    // オンライン時はバックグラウンドで未送信データの同期とリモートデータの取得を行う
    if (!_hasSyncedOnInitialOnline && ref.watch(isOnlineProvider)) {
      _hasSyncedOnInitialOnline = true;
      unawaited(_syncAndFetch(repository, userId));
    }

    // 検索・絞り込み条件を監視します
    final filter = ref.watch(memoFilterProvider);

    // データベースから条件に合致するメモをストリームで監視します
    final memosStream = filter.hasActiveFilter
        ? repository.watchFilteredMemos(
            userId,
            query: filter.query,
            category: filter.category,
            unsyncedOnly: filter.unsyncedOnly ? true : null,
          )
        : repository.watchAllMemos(userId);

    return memosStream.map((filteredMemos) {
      final sortedMemos = _sortMemos(filteredMemos, filter.sortOrder);

      // 並び替え処理が実行中でなければ、確定した最新順序として記録
      if (_activeReorderCount == 0) {
        _lastConfirmedMemos = sortedMemos;
      }

      return sortedMemos;
    });
  }

  /// メモ一覧を指定されたソート順で並べ替えた新しいリストを返す
  List<MemoModel> _sortMemos(List<MemoModel> memos, MemoSortOrder sortOrder) {
    // 破壊的変更を避けるためにリストをコピーしてソート
    final sortedMemos = [...memos];

    final comparator = switch (sortOrder) {
      MemoSortOrder.createdAtDesc =>
        (MemoModel a, MemoModel b) => b.createdAt.compareTo(a.createdAt),
      MemoSortOrder.createdAtAsc =>
        (MemoModel a, MemoModel b) => a.createdAt.compareTo(b.createdAt),
      MemoSortOrder.updatedAtDesc =>
        (MemoModel a, MemoModel b) => b.updatedAt.compareTo(a.updatedAt),
      MemoSortOrder.updatedAtAsc =>
        (MemoModel a, MemoModel b) => a.updatedAt.compareTo(b.updatedAt),
      MemoSortOrder.titleAsc => (MemoModel a, MemoModel b) => a.title.compareTo(
        b.title,
      ),
      MemoSortOrder.titleDesc =>
        (MemoModel a, MemoModel b) => b.title.compareTo(a.title),
      MemoSortOrder.custom =>
        (MemoModel a, MemoModel b) => a.sortOrder.compareTo(b.sortOrder),
    };
    sortedMemos.sort(comparator);
    return sortedMemos;
  }

  /// ロールバック時の並び順を構築する
  ///
  /// [sortOrder] が [MemoSortOrder.custom] の場合は、既存の確定メモの
  /// 相対順（[confirmed]）を維持し、保存待機中に追加・復元された新規メモは
  /// 最新のDB順（[latest]）上の位置を保ちます。
  /// また、[latest] に存在しない削除済みメモは除外して復活を防ぎます。
  /// それ以外のソート条件では確定順へ戻さず、[latest] の順を維持します。
  List<MemoModel> _mergeRollbackMemos({
    required List<MemoModel> confirmed,
    required List<MemoModel> latest,
    required MemoSortOrder sortOrder,
  }) {
    if (sortOrder != MemoSortOrder.custom) {
      return [...latest];
    }
    final latestById = {for (final memo in latest) memo.id: memo};
    final confirmedIdSet = <String>{};
    final orderedConfirmed = <MemoModel>[];

    // 確定済みメモの相対順を保ちつつ、削除されたメモは除外し、最新モデルへ差し替える
    for (final memo in confirmed) {
      if (confirmedIdSet.add(memo.id)) {
        final latestMemo = latestById[memo.id];
        if (latestMemo != null) {
          orderedConfirmed.add(latestMemo);
        }
      }
    }

    // 最新一覧の中で「既存メモの枠」には確定順のメモを順に当てはめ、
    // 新規メモはDB上の位置をそのまま維持する
    var confirmedIndex = 0;
    return [
      for (final memo in latest)
        if (confirmedIdSet.contains(memo.id) &&
            confirmedIndex < orderedConfirmed.length)
          orderedConfirmed[confirmedIndex++]
        else
          memo,
    ];
  }

  /// 非同期でサーバーとのデータ同期およびマージを実行する
  Future<void> _syncAndFetch(MemoRepository repository, String userId) async {
    try {
      await repository.fetchAndMergeRemoteMemos(userId);
    } on Exception catch (e, st) {
      ref.read(loggerProvider).handle(e, st, 'バックグラウンド同期中にエラーが発生しました');
    }
  }

  /// 新しいメモを追加する
  Future<void> addMemo(
    String title,
    String content, {
    MemoCategory? category,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.addMemo(title, content, userId, category: category);
  }

  /// Undo通知の表示中などに画面遷移しても復元できるよう、Notifierを一時保持する
  void Function() retainForUndo() {
    final link = ref.keepAlive();
    return link.close;
  }

  /// メモを削除する（ローカル削除のみ待機し、リモート同期はバックグラウンドで順序保証実行）
  Future<void> deleteMemo(String id) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.deleteMemo(id, userId, waitForRemoteSync: false);
  }

  /// 削除されたメモを復元（Undo）する
  Future<void> restoreMemo(String id, {String? expectedUserId}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null ||
        (expectedUserId != null && userId != expectedUserId)) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.restoreMemo(id, userId, waitForRemoteSync: false);
  }

  /// メモの並び順（ドラッグ＆ドロップ）を更新する（Optimistic UI対応）
  Future<void> reorderMemos(int oldIndex, int newIndex) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final currentMemos = state.asData?.value;
    if (currentMemos == null || currentMemos.isEmpty) {
      return;
    }

    // 検索・絞り込み中は手動並び替え不可
    final initialFilter = ref.read(memoFilterProvider);
    if (initialFilter.hasActiveFilter) {
      return;
    }

    final targetIndex = newIndex;
    final itemCount = currentMemos.length;
    // カウンターや確定済み順序を変更する前に、oldIndex・targetIndex がリスト範囲内かつ異なる位置か検証する
    if (oldIndex < 0 ||
        oldIndex >= itemCount ||
        targetIndex < 0 ||
        targetIndex >= itemCount ||
        oldIndex == targetIndex) {
      return;
    }

    final initialAuthGeneration = _authGeneration;

    // 進行中の並び替えがなければ、現在の状態を「最後に保存が確認された順序」として保持
    if (_activeReorderCount == 0) {
      _lastConfirmedMemos = currentMemos;
    }
    _activeReorderCount++;

    // 画面のチラつき（DriftのStreamラグ）を防ぐため、即座にローカル状態（state）を並び替える（Optimistic UI）
    final updatedMemos = [...currentMemos];
    final movedItem = updatedMemos.removeAt(oldIndex);
    updatedMemos.insert(targetIndex, movedItem);
    state = AsyncData(updatedMemos);

    final repository = ref.read(memoRepositoryProvider);
    final logger = ref.read(loggerProvider);
    final orderedIds = updatedMemos.map((m) => m.id).toList();

    try {
      await repository.updateSortOrders(orderedIds, userId);

      // 待機中にプロバイダ破棄または認証世代が変化した場合は、
      // 旧ユーザーの保存結果で新ユーザーの確定順序やフィルタを上書きしないよう破棄する
      if (!ref.mounted || initialAuthGeneration != _authGeneration) {
        return;
      }

      // 保存に成功した順序を確定順序として記録
      _lastConfirmedMemos = updatedMemos;

      // 保存成功後に、ソート順を「カスタム順（手動並び順）」に切り替える
      // ただし、待機中にユーザーが別のソートやフィルタに変更していない場合のみ
      final currentFilter = ref.read(memoFilterProvider);
      if (currentFilter == initialFilter &&
          currentFilter.sortOrder != MemoSortOrder.custom) {
        ref
            .read(memoFilterProvider.notifier)
            .setSortOrder(MemoSortOrder.custom);
      }
    } on Exception catch (e, st) {
      logger.handle(e, st, 'メモの並び替え保存に失敗しました');

      // 待機中にプロバイダ破棄または認証世代が変化した場合は、
      // 旧ユーザーの結果を破棄し、旧データでの状態復元および新画面へのエラー再スローを行わない
      if (!ref.mounted || initialAuthGeneration != _authGeneration) {
        return;
      }

      // 失敗した場合は、最後に保存が確認された順序にロールバック
      // ただし、待機中に検索・フィルタ条件が変更されている場合は、
      // 検索結果の表示を壊さないようロールバック（stateの上書き）をスキップする
      final filterBeforeFetch = ref.read(memoFilterProvider);
      if (filterBeforeFetch == initialFilter &&
          !filterBeforeFetch.hasActiveFilter) {
        // 待機中に追加・削除されたメモがストリームから未反映でも正しいDB位置を保つため、
        // 最新のローカルDB一覧を取得してソート済みの基準順序を作る
        List<MemoModel>? latestDbMemos;
        try {
          latestDbMemos = await repository.getLocalMemos(userId);
        } on Object catch (fetchError, fetchSt) {
          logger.handle(fetchError, fetchSt, 'ロールバック用の最新メモ取得に失敗しました');
        }

        if (!ref.mounted || initialAuthGeneration != _authGeneration) {
          return;
        }

        final currentFilter = ref.read(memoFilterProvider);
        if (currentFilter == initialFilter && !currentFilter.hasActiveFilter) {
          final confirmed = _lastConfirmedMemos ?? currentMemos;
          final fallbackLatest = state.asData?.value ?? currentMemos;
          final latest = latestDbMemos != null
              ? _sortMemos(latestDbMemos, currentFilter.sortOrder)
              : (currentFilter.sortOrder == MemoSortOrder.custom
                    ? fallbackLatest
                    : _sortMemos(fallbackLatest, currentFilter.sortOrder));
          state = AsyncData(
            _mergeRollbackMemos(
              confirmed: confirmed,
              latest: latest,
              sortOrder: currentFilter.sortOrder,
            ),
          );
        }
      }
      rethrow;
    } finally {
      if (ref.mounted && initialAuthGeneration == _authGeneration) {
        _activeReorderCount--;
        if (_activeReorderCount <= 0) {
          _activeReorderCount = 0;
        }
      }
    }
  }

  /// 手動同期を実行する
  Future<void> sync() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    if (ref.read(isOnlineProvider)) {
      await repository.fetchAndMergeRemoteMemos(userId);
    }
  }
}
