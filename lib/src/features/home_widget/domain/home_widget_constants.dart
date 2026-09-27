/// ホーム画面ウィジェット連携で使用する定数定義
abstract final class HomeWidgetConstants {
  /// パッケージ名（Bundle ID）から App Group ID を動的に生成する
  static String appGroupIdFor(String packageName) => 'group.$packageName';

  /// iOS側のウィジェット名（SwiftUIのWidgetBundleで登録する名前）
  static const iOSWidgetName = 'MemoWidget';

  /// Android側のウィジェット名（AppWidgetProviderのクラス名）
  static const androidWidgetName = 'MemoWidgetProvider';

  /// ウィジェットに保存するキー名: メモの総件数
  static const keyMemoCount = 'widget_memo_count';

  /// ウィジェットに保存するキー名: 最新メモのID
  static const keyLatestMemoId = 'widget_memo_id';

  /// ウィジェットに保存するキー名: 最新メモのタイトル
  static const keyLatestMemoTitle = 'widget_memo_title';

  /// ウィジェットに保存するキー名: 最新メモの本文プレビュー
  static const keyLatestMemoContent = 'widget_memo_content';

  /// ウィジェットに保存するキー名: 最新メモの更新日時（表示用フォーマット文字列）
  static const keyLatestMemoUpdatedAt = 'widget_memo_updated_at';

  /// ディープリンク用URLスキーム（各Flavor共通のベース定義）
  static const deepLinkScheme = 'flsamplelocal';

  /// ディープリンク用ホスト名
  static const deepLinkHost = 'memos';

  /// ディープリンク用パス: メモ新規作成
  static const deepLinkPathCreate = '/memos/create';

  /// ディープリンク用クエリパラメータキー: メモID
  static const deepLinkQueryParamId = 'id';
}
