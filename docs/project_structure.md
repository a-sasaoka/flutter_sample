# ディレクトリ構成

以下はプロジェクトの主要ディレクトリとファイルの構成です。
それぞれの役割をコメントで補足しています。
自動生成ファイルは原則除外しています。

```plaintext
flutter_sample
├── .env*                                                       # 環境毎の設定ファイル（Gitでは管理しない。env.example参照）
├── .github/                                                    # GitHub ActionsによるCI/CDワークフロー設定
├── docs/                                                       # プロジェクトの詳細な仕様・ドキュメント群
├── test/                                                       # テストコード（lib配下と完全に1対1のディレクトリ構成）
├── tool/                                                       # 開発補助スクリプト（Git Hooks等）
└── lib
    ├── firebase_options_*.dart                                 # FlutterFire CLIで自動生成されるファイル（Gitでは管理しない）
    ├── main.dart                                               # アプリのエントリーポイント。最初に実行されるファイル
    ├── l10n                                                    # 多言語対応用のARBファイルを格納するディレクトリ
    │   ├── app_en.arb                                          # 英語翻訳ファイル
    │   └── app_ja.arb                                          # 日本語翻訳ファイル
    └── src
        ├── app                                                 # アプリケーション全体の構成要素
        │   ├── database                                        # Driftデータベース本体（テーブル統合管理）
        │   └── router                                          # ルーティング（GoRouter）関連・認証ガード
        ├── core                                                # アプリ全体で共通的に利用される基盤コード
        │   ├── analytics                                       # イベント計測関連
        │   ├── config                                          # 環境設定やテーマ、プロバイダー設定など
        │   ├── database                                        # データベースインスタンスの提供
        │   ├── exceptions                                      # 共通の例外クラス定義
        │   ├── network                                         # APIクライアント、Interceptor
        │   ├── storage                                         # 永続化関連（SharedPreferences・SecureStorage・キャッシュ）
        │   ├── ui                                              # 共通UI関連（エラーハンドリングなど）
        │   ├── utils                                           # 共通ユーティリティ（ロギング・通信状態・ライフサイクル監視等）
        │   └── widgets                                         # 汎用UI部品（ダイアログや共通画面）
        └── features                                            # 各機能ごとのモジュール（Layered Architecture）
            ├── auth                                            # 認証機能
            ├── chart                                           # グラフ表示機能（fl_chart）
            ├── chat                                            # AIチャット機能
            ├── home                                            # ホーム画面
            ├── memos                                           # メモ一覧・オフライン操作機能
            ├── settings                                        # 設定画面
            ├── splash                                          # スプラッシュ画面
            └── user                                            # ユーザー管理機能
                ├── application                                 # 状態管理・ビジネスロジック (Notifier)
                ├── data                                        # データ取得処理 (Repository / API)
                ├── domain                                      # ドメインモデル・エンティティ定義 (Model)
                └── presentation                                # 画面(UI)層 (Screen / Widget)
```

---
