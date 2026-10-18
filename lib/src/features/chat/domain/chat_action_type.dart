import 'package:flutter_sample/src/features/chat/domain/chat_action_constants.dart';

/// チャットでAIが呼び出すアプリ機能（ツール）の種類
enum ChatActionType {
  /// メモの新規作成
  createMemo,

  /// メモの一覧取得・キーワード検索
  listMemos,

  /// テーマモード（ライト/ダーク/システム）の切り替え
  changeThemeMode;

  /// Geminiからの関数名（文字列）を安全にEnumへ変換するヘルパー
  static ChatActionType? fromFunctionName(String name) {
    return switch (name) {
      ChatActionNames.createMemo => ChatActionType.createMemo,
      ChatActionNames.listMemos => ChatActionType.listMemos,
      ChatActionNames.changeThemeMode => ChatActionType.changeThemeMode,
      _ => null,
    };
  }
}
