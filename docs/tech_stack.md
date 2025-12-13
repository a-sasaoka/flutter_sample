# 技術スタックと開発環境

## 採用技術

| 分類             | 使用技術                                                                                                                                                                                |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 状態管理           | [Riverpod](https://riverpod.dev) + [Flutter Hooks](https://pub.dev/packages/flutter_hooks)                                                                                          |
| ルーティング         | [GoRouter](https://pub.dev/packages/go_router) + [go_router_builder](https://pub.dev/packages/go_router_builder)                                                                  |
| 通信             | [Dio](https://pub.dev/packages/dio) + [pretty_dio_logger](https://pub.dev/packages/pretty_dio_logger)                                                                             |
| モデル生成          | [Freezed](https://pub.dev/packages/freezed) + [json_serializable](https://pub.dev/packages/json_serializable)                                                                      |
| 環境変数           | [Envied](https://pub.dev/packages/envied)                                                                                                                                           |
| テーマ管理          | [Flex Color Scheme](https://pub.dev/packages/flex_color_scheme)                                                                                                                     |
| ログ             | [Logger](https://pub.dev/packages/logger)                                                                                                                                           |
| Lint / 静的解析    | [very_good_analysis](https://pub.dev/packages/very_good_analysis), [custom_lint](https://pub.dev/packages/custom_lint), [riverpod_lint](https://pub.dev/packages/riverpod_lint) |
| Flutterバージョン管理 | [FVM](https://fvm.app) (`3.35.7` 使用)                                                                                                                                                |

---

## 開発環境

| 項目          | 内容                        |
| ----------- | ------------------------- |
| IDE         | Visual Studio Code        |
| Flutter SDK | 管理: FVM / バージョン: 3.35.7   |
| Dart SDK    | 3.9.2                     |
| GitHub管理    | Git（`.gitkeep`で空ディレクトリ管理） |
