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
      // 破壊的変更を避けるためにリストをコピーしてソート
      final sortedMemos = [...filteredMemos];

      final comparator = switch (filter.sortOrder) {
        MemoSortOrder.createdAtDesc =>
          (MemoModel a, MemoModel b) => b.createdAt.compareTo(a.createdAt),
        MemoSortOrder.createdAtAsc =>
          (MemoModel a, MemoModel b) => a.createdAt.compareTo(b.createdAt),
        MemoSortOrder.updatedAtDesc =>
          (MemoModel a, MemoModel b) => b.updatedAt.compareTo(a.updatedAt),
        MemoSortOrder.updatedAtAsc =>
          (MemoModel a, MemoModel b) => a.updatedAt.compareTo(b.updatedAt),
        MemoSortOrder.titleAsc =>
          (MemoModel a, MemoModel b) => a.title.compareTo(b.title),
        MemoSortOrder.titleDesc =>
          (MemoModel a, MemoModel b) => b.title.compareTo(a.title),
        MemoSortOrder.custom =>
          (MemoModel a, MemoModel b) => a.sortOrder.compareTo(b.sortOrder),
      };
      sortedMemos.sort(comparator);

      // 並び替え処理が実行中でなければ、確定した最新順序として記録
      if (_activeReorderCount == 0) {
        _lastConfirmedMemos = sortedMemos;
      }

      return sortedMemos;
    });
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

  /// メモを削除する
  Future<void> deleteMemo(String id) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.deleteMemo(id, userId);
  }

  /// 削除されたメモを復元（Undo）する
  Future<void> restoreMemo(String id) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.restoreMemo(id, userId);
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
      final currentFilter = ref.read(memoFilterProvider);
      if (currentFilter == initialFilter && !currentFilter.hasActiveFilter) {
        final confirmed = _lastConfirmedMemos ?? currentMemos;
        final current = state.asData?.value ?? currentMemos;
        // 確定順序（並び替え前の位置）の背番号マップを作成
        final confirmedOrderMap = {
          for (var i = 0; i < confirmed.length; i++) confirmed[i].id: i,
        };
        // 現在画面に存在するメモだけを、並び替え前の確定順に従ってソートし直す
        // ※ これにより、並び替え待機中に削除されたメモが復活するのを防ぐ
        final rolledBackMemos = [...current]
          ..sort((a, b) {
            final orderA = confirmedOrderMap[a.id] ?? 999999;
            final orderB = confirmedOrderMap[b.id] ?? 999999;
            return orderA.compareTo(orderB);
          });
        state = AsyncData(rolledBackMemos);
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
