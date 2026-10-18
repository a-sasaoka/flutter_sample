import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
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
      null => {'status': 'error', 'error': 'Unsupported action: $name'},
    };
  }

  /// メモ新規作成を実行
  Future<Map<String, Object?>> _createMemo(Map<String, Object?> args) async {
    final title = args['title'] as String?;
    final content = args['content'] as String? ?? '';

    // タイトルのバリデーション（ユーザーの入力ミス）
    if (title == null || title.trim().isEmpty) {
      return {'status': 'error', 'error': 'Title is required for createMemo'};
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return {'status': 'error', 'error': 'User is not logged in'};
    }

    try {
      await _ref
          .read(memoProvider.notifier)
          .addMemo(title.trim(), content.trim());
      return {'status': 'success', 'title': title.trim()};
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to create memo via AI tool');
      return {'status': 'error', 'error': 'Failed to create memo: $e'};
    }
  }

  /// メモ一覧・検索を実行
  Future<Map<String, Object?>> _listMemos(Map<String, Object?> args) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return {'status': 'error', 'error': 'User is not logged in'};
    }

    try {
      final query = (args['query'] as String?)?.trim().toLowerCase();
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
        'status': 'success',
        'count': filtered.length,
        'memos': filtered
            .map((m) => {'id': m.id, 'title': m.title, 'content': m.content})
            .toList(),
      };
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to list memos via AI tool');
      return {'status': 'error', 'error': 'Failed to list memos: $e'};
    }
  }

  /// テーマモード変更を実行
  Future<Map<String, Object?>> _changeThemeMode(
    Map<String, Object?> args,
  ) async {
    final themeStr = (args['theme'] as String?)?.toLowerCase();
    final mode = switch (themeStr) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => null,
    };

    if (mode == null) {
      return {
        'status': 'error',
        'error':
            'Invalid theme: $themeStr. Allowed values are system, light, dark.',
      };
    }

    try {
      await _ref.read(themeModeProvider.notifier).set(mode);
      return {'status': 'success', 'theme': mode.name};
    } on Exception catch (e, st) {
      _ref
          .read(loggerProvider)
          .handle(e, st, 'Failed to change theme mode via AI tool');
      return {'status': 'error', 'error': 'Failed to change theme: $e'};
    }
  }
}
