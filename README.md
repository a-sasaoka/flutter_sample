# Flutter Sample Project

Flutter開発のサンプルプロジェクトです。\
初学者から中級者まで、実践的なアプリ構成や開発環境の整備方法を学ぶことができます。

このREADMEはインデックスです。詳細な説明は `docs/` 以下の章を参照してください。

---

## 目次

### A. 基本情報

- [プロジェクト概要](docs/overview.md)
- [技術スタックと開発環境](docs/tech_stack.md)
- [ディレクトリ構成](docs/project_structure.md)

### B. 開発準備

- [初期セットアップ](docs/setup.md)

### C. アプリ基盤

- [GoRouter（型安全ルーティング）](docs/routing.md)
- [Flavor管理（マルチ環境対応）](docs/flavor.md)
- [多言語対応（Localization）](docs/localization.md)
- [データ永続化・ローカルDB（SharedPreferences / Drift / Secure Storage）](docs/persistence.md)
- [テーマ設定（FlexColorScheme）](docs/theme.md)
- [共通ユーティリティ（ログ・通信状態・ライフサイクル）](docs/core_utilities.md)

### D. 機能別実装

- [API通信デモ（UserList）](docs/api_and_error_handling.md)
- [トークン認証（Bearer + Refresh）](docs/auth.md)
- [Firebase Authenticationによる認証対応](docs/firebase_authentication.md)
- [APIキャッシュ対応（SharedPreferencesAsyncベース）](docs/cache.md)
- [Firebase Crashlytics](docs/crashlytics.md)
- [Firebase Analytics](docs/analytics.md)
- [バージョンアップ通知（Firebase Remote Config）](docs/remote_config.md)
- [AIチャット機能 (Firebase AI Logic)](docs/ai_chat.md)
- [fl_chart によるグラフ表示デモ](docs/chart.md)
- [Driftによるオフラインデータ操作（Memos）](docs/persistence.md)

### E. 開発運用

- [コード生成コマンド](docs/code_generation.md)
- [今後の拡張案](docs/roadmap.md)
