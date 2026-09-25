import 'dart:ui';

/// 📤 SNSシェア機能に関するURLやデフォルト設定を管理するクラス
abstract final class ShareConfig {
  /// X (旧Twitter) Web Intent のホスト名
  static const String xIntentHost = 'twitter.com';

  /// X (旧Twitter) Web Intent のパス
  static const String xIntentPath = '/intent/tweet';

  /// LINE メッセージ送信 URL（URLスキーム）
  static const String lineMessageBaseUrl = 'https://line.me/R/msg/text/?';

  /// デモ画面等のデフォルト共有URL
  static const String defaultShareUrl =
      'https://github.com/a-sasaoka/flutter_sample';

  /// X (旧Twitter) 共有時のデフォルトハッシュタグ
  static const List<String> defaultHashtags = ['Flutter', '個人開発'];

  /// iPad等で吹き出し位置が未指定の場合にクラッシュを防ぐデフォルトの座標
  static const Rect defaultSharePositionOrigin = Rect.fromLTWH(0, 0, 100, 100);
}
