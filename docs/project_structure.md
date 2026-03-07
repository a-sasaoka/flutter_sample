# ディレクトリ構成

以下はプロジェクトの主要ディレクトリとファイルの構成です。
それぞれの役割をコメントで補足しています。
自動生成ファイルは原則除外しています。

```plaintext
flutter_sample
├── .end.*.                                                     # 環境毎の設定ファイル（Gitでは管理しない）
└── lib
    ├── firebase_options_*.dart                                 # FlutterFire CLIで自動生成されるファイル（Gitでは管理しない）
    ├── main.dart                                               # アプリのエントリーポイント。最初に実行されるファイル
    ├── l10n                                                    # 多言語対応用のARBファイルを格納するディレクトリ
    │   ├── app_en.arb                                          # 英語翻訳ファイル　
    │   └── app_ja.arb                                          # 日本語翻訳ファイル
    └── src
        ├── core                                                # アプリ全体で共通的に利用される基盤コード
        │   ├── analytics                                       # イベント計測関連
        │   ├── config                                          # 環境設定やテーマ、共有設定など
        │   ├── exceptions                                      # 共通の例外クラス定義
        │   ├── network                                         # 通信関連の設定やロギング
        │   ├── router                                          # ルーティング（GoRouter）関連
        │   ├── storage                                         # 永続化関連（SharedPreferencesベースのキャッシュなど）
        │   ├── ui                                              # 共通UI関連（エラーハンドリングなど）
        │   ├── utils                                           # 共通のユーティリティ関数群
        │   └── widgets                                         # 汎用UI部品や画面
        └── features                                            # 各機能（画面単位）ごとのモジュール
            ├── (機能)                                           # 各機能
            │   ├── application                                 # 状態管理・ビジネスロジック
            │   ├── data                                        # データ取得処理（APIやDBアクセス）
            │   ├── domain                                      # ドメインモデル・エンティティ定義
            │   └── presentation                                # 画面(UI)層
```

---
