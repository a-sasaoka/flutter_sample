/// AIツール呼び出し（Function Calling）で使う関数名
abstract final class ChatActionNames {
  /// メモの新規作成 ('createMemo')
  static const createMemo = 'createMemo';

  /// メモ一覧・検索 ('listMemos')
  static const listMemos = 'listMemos';

  /// テーマモードの変更 ('changeThemeMode')
  static const changeThemeMode = 'changeThemeMode';

  /// Web検索 ('searchWeb')
  static const searchWeb = 'searchWeb';
}

/// AIツール実行の共通結果ステータス
abstract final class ChatActionResultKeys {
  /// ステータス判定キー ('status')
  static const status = 'status';

  /// 成功 ('success')
  static const success = 'success';

  /// 失敗 ('error')
  static const error = 'error';

  /// エラー詳細メッセージ ('error')
  static const errorMessage = 'error';
}

/// メモ新規作成（createMemo）ツールの引数・結果キー
abstract final class CreateMemoActionKeys {
  /// メモのタイトル ('title')
  static const title = 'title';

  /// メモの本文 ('content')
  static const content = 'content';
}

/// メモ一覧・検索（listMemos）ツールの引数・結果キー
abstract final class ListMemosActionKeys {
  /// 検索キーワード ('query')
  static const query = 'query';

  /// 取得件数 ('count')
  static const count = 'count';

  /// メモ一覧リスト ('memos')
  static const memos = 'memos';
}

/// テーマ変更（changeThemeMode）ツールの引数・結果キー
abstract final class ChangeThemeActionKeys {
  /// テーマ指定パラメータ ('theme')
  static const theme = 'theme';

  /// システム設定追従 ('system')
  static const system = 'system';

  /// ライトモード ('light')
  static const light = 'light';

  /// ダークモード ('dark')
  static const dark = 'dark';
}

/// Web検索（searchWeb）ツールの引数・結果キー
abstract final class SearchWebActionKeys {
  /// 検索クエリ ('query')
  static const query = 'query';

  /// 記事タイトル ('title')
  static const title = 'title';

  /// 要約・スニペット ('snippet')
  static const snippet = 'snippet';

  /// 記事URL ('url')
  static const url = 'url';

  /// 検索結果リスト ('results')
  static const results = 'results';

  /// メッセージキー ('message')
  static const message = 'message';
}
