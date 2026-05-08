# プロジェクト概要

このプロジェクトは、Flutterを用いたアプリ開発で役立つ構成・設定を体系的にまとめたテンプレートです。\
特に以下の技術スタックを採用し、実務でも通用する設計を意識しています。

---

## このプロジェクトで学べること

このサンプルプロジェクトを通して、以下の技術や設計手法を体系的に学ぶことができます。

| 分野              | 学べる内容                                                                           |
| ----------------- | ------------------------------------------------------------------------------------ |
| 🧠 状態管理       | Riverpod + Flutter Hooks による状態管理とロジックの分離                              |
| 🧭 ルーティング   | GoRouter + go_router_builder による型安全なルート設計と認証ガード                    |
| 🌐 通信           | Dio + Interceptorによる共通通信層とエラーハンドリング、接続状態の監視(Connectivity)  |
| 🔒 認証           | Firebase Auth（メール/Googleログイン） / Bearerトークンの自動リフレッシュ            |
| 💾 データ保持     | SharedPreferencesAsync / SecureStorage / Drift(SQLite) による永続化とオフライン対応  |
| 📝 ロギング       | Talkerを用いた統合ログ管理（通信・状態・Crashlytics連携）とアプリ内開発者用画面      |
| 🌍 多言語対応     | flutter_localizations + gen-l10n による標準的な多言語化                              |
| 🔥 Firebase       | Auth / Analytics / Crashlytics / Remote Config / App Check を組み合わせた基盤構築    |
| 📈 グラフ         | fl_chart を用いた動的なグラフ（折れ線・棒・円）の表示とデータ入力                    |
| 🤖 生成AI         | Firebase AI Logic（firebase_ai）を用いたストリーミング応答と履歴保持チャット         |
| 🧰 コード生成     | build_runnerによる自動生成と、JSON/Enviedを組み合わせた高度な環境切替対応            |
| 🎨 UI             | FlexColorSchemeによるテーマ設定と共通エラーハンドリングUI / Markdown表示             |
| 🧪 テスト         | mocktail等を用いた実践的なユニットテスト・ウィジェットテストの手法                   |
| 🧩 Lint・CI/CD    | custom_lint 等の実用設定と、GitHub Actions による自動化（CI/CD）基盤                 |
| 🚀 開発効率       | FVM + VSCode設定 + Git Hooks で統一開発環境を構築                                    |
| 🏗️ アーキテクチャ | マルチエントリーポイントによるFlavor（Local/Dev/Stg/Prod）の完全分離と堅牢な管理方式 |

---
