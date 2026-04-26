# 技術スタックと開発環境

## 採用技術

| 分類                  | 使用技術                                                                                                                                                                                                                                 |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Flutterバージョン管理 | [FVM](https://fvm.app)（バージョン: `3.35.7`）                                                                                                                                                                                           |
| 状態管理              | [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) + [Hooks Riverpod](https://pub.dev/packages/hooks_riverpod) + [Flutter Hooks](https://pub.dev/packages/flutter_hooks)                                                      |
| ルーティング          | [Go Router](https://pub.dev/packages/go_router) + [Go Router Builder](https://pub.dev/packages/go_router_builder)                                                                                                                        |
| テーマ管理            | [Flex Color Scheme](https://pub.dev/packages/flex_color_scheme)                                                                                                                                                                          |
| 多言語対応            | [Flutter Localizations](https://pub.dev/packages/flutter_localizations) + [Intl](https://pub.dev/packages/intl)                                                                                                                          |
| 通信                  | [Dio](https://pub.dev/packages/dio) + [Talker Dio Logger](https://pub.dev/packages/talker_dio_logger)                                                                                                                                    |
| モデル生成            | [Freezed](https://pub.dev/packages/freezed) + [Json Serializable](https://pub.dev/packages/json_serializable)                                                                                                                            |
| コード生成            | [Build Runner](https://pub.dev/packages/build_runner) + [Riverpod Generator](https://pub.dev/packages/riverpod_generator)                                                                                                                |
| 環境変数              | [Envied](https://pub.dev/packages/envied)                                                                                                                                                                                                |
| ログ                  | [Talker](https://pub.dev/packages/talker_flutter)                                                                                                                                                                                        |
| Firebase基盤          | [Firebase Core](https://pub.dev/packages/firebase_core)                                                                                                                                                                                  |
| イベント計測          | [Firebase Analytics](https://pub.dev/packages/firebase_analytics)                                                                                                                                                                        |
| クラッシュ収集        | [Firebase Crashlytics](https://pub.dev/packages/firebase_crashlytics)                                                                                                                                                                    |
| リモート設定          | [Firebase Remote Config](https://pub.dev/packages/firebase_remote_config)                                                                                                                                                                |
| 認証                  | [Firebase Authentication](https://pub.dev/packages/firebase_auth) + [Google Sign In](https://pub.dev/packages/google_sign_in)                                                                                                            |
| セキュリティ          | [Firebase App Check](https://pub.dev/packages/firebase_app_check)                                                                                                                                                                        |
| AI / 機械学習         | [Firebase AI](https://pub.dev/packages/firebase_ai)                                                                                                                                                                                      |
| 端末情報              | [Package Info Plus](https://pub.dev/packages/package_info_plus)                                                                                                                                                                          |
| ローカル保存          | [Shared Preferences](https://pub.dev/packages/shared_preferences) + [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)                                                                                            |
| ユーティリティ        | [UUID](https://pub.dev/packages/uuid), [Version](https://pub.dev/packages/version), [Flutter Markdown Plus](https://pub.dev/packages/flutter_markdown_plus), [Connectivity Plus](https://pub.dev/packages/connectivity_plus)             |
| テスト                | [Flutter Test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) + [Mocktail](https://pub.dev/packages/mocktail)                                                                                                   |
| Lint / 静的解析       | [Very Good Analysis](https://pub.dev/packages/very_good_analysis), [Custom Lint](https://pub.dev/packages/custom_lint), [Riverpod Lint](https://pub.dev/packages/riverpod_lint), [Flutter Lints](https://pub.dev/packages/flutter_lints) |

---

## 開発環境

| 項目        | 内容                           |
| ----------- | ------------------------------ |
| IDE         | Visual Studio Code             |
| Flutter SDK | 管理: FVM / バージョン: 3.35.7 |
| Dart SDK    | 3.9.2                          |
| GitHub管理  | Git                            |
