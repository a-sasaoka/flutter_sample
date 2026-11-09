import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/services/web_search_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_constants.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_type.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// アプリ機能（ツール）の実行ディスパッチャーの具象クラス
class AppActionDispatcherImpl implements AppActionDispatcher {
  /// コンストラクタ
  const AppActionDispatcherImpl(this._ref);

  final Ref _ref;

  @override
  Future<Map<String, Object?>> execute({
    required String name,
    required Map<String, Object?> args,
  }) async {
    final actionType = ChatActionType.fromFunctionName(name);
    return switch (actionType) {
      ChatActionType.createMemo => await _createMemo(args),
      ChatActionType.listMemos => await _listMemos(args),
      ChatActionType.changeThemeMode => await _changeThemeMode(args),
      ChatActionType.searchWeb => await _searchWeb(args),
      null => {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Unsupported action: $name',
      },
    };
  }

  /// メモ新規作成を実行
  Future<Map<String, Object?>> _createMemo(Map<String, Object?> args) async {
    final title = args[CreateMemoActionKeys.title] as String?;
    final content = args[CreateMemoActionKeys.content] as String? ?? '';

    // タイトルのバリデーション（ユーザーの入力ミス）
    if (title == null || title.trim().isEmpty) {
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Title is required for createMemo',
      };
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'User is not logged in',
      };
    }

    try {
      await _ref
          .read(memoProvider.notifier)
          .addMemo(title.trim(), content.trim());
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.success,
        CreateMemoActionKeys.title: title.trim(),
      };
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to create memo via AI tool');
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Failed to create memo: $e',
      };
    }
  }

  /// メモ一覧・検索を実行
  Future<Map<String, Object?>> _listMemos(Map<String, Object?> args) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'User is not logged in',
      };
    }

    try {
      final query = (args[ListMemosActionKeys.query] as String?)
          ?.trim()
          .toLowerCase();
      final repository = _ref.read(memoRepositoryProvider);
      final memos = await repository.getAllMemos(userId);

      final filtered = (query != null && query.isNotEmpty)
          ? memos.where((m) {
              final t = m.title.toLowerCase();
              final c = m.content.toLowerCase();
              return t.contains(query) || c.contains(query);
            }).toList()
          : memos;

      return {
        ChatActionResultKeys.status: ChatActionResultKeys.success,
        ListMemosActionKeys.count: filtered.length,
        ListMemosActionKeys.memos: filtered
            .map((m) => {'id': m.id, 'title': m.title, 'content': m.content})
            .toList(),
      };
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to list memos via AI tool');
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Failed to list memos: $e',
      };
    }
  }

  /// テーマモード変更を実行
  Future<Map<String, Object?>> _changeThemeMode(
    Map<String, Object?> args,
  ) async {
    final themeStr = (args[ChangeThemeActionKeys.theme] as String?)
        ?.toLowerCase();
    final mode = switch (themeStr) {
      ChangeThemeActionKeys.system => ThemeMode.system,
      ChangeThemeActionKeys.light => ThemeMode.light,
      ChangeThemeActionKeys.dark => ThemeMode.dark,
      _ => null,
    };

    if (mode == null) {
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage:
            'Invalid theme: $themeStr. Allowed values are system, light, dark.',
      };
    }

    try {
      await _ref.read(themeModeProvider.notifier).set(mode);
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.success,
        ChangeThemeActionKeys.theme: mode.name,
      };
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to change theme mode via AI tool');
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Failed to change theme: $e',
      };
    }
  }

  /// Web検索（Wikipedia）を実行
  Future<Map<String, Object?>> _searchWeb(Map<String, Object?> args) async {
    final query = args[SearchWebActionKeys.query] as String?;
    if (query == null || query.trim().isEmpty) {
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Query is required for searchWeb',
      };
    }

    final trimmedQuery = query.trim();
    try {
      final results = await _ref
          .read(webSearchServiceProvider)
          .search(trimmedQuery);

      if (results.isEmpty) {
        return {
          ChatActionResultKeys.status: ChatActionResultKeys.success,
          SearchWebActionKeys.query: trimmedQuery,
          SearchWebActionKeys.results: const <Map<String, Object?>>[],
          SearchWebActionKeys.message: 'No articles found for "$trimmedQuery".',
        };
      }

      return {
        ChatActionResultKeys.status: ChatActionResultKeys.success,
        SearchWebActionKeys.query: trimmedQuery,
        SearchWebActionKeys.results: results.map((r) => r.toMap()).toList(),
      };
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to search web via AI tool');
      return {
        ChatActionResultKeys.status: ChatActionResultKeys.error,
        ChatActionResultKeys.errorMessage: 'Failed to search web: $e',
      };
    }
  }
}
