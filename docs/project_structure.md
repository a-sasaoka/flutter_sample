# ディレクトリ構成

以下は `lib` 以下のディレクトリと主要ファイル構成です。  
それぞれの役割をコメントで補足しています。

```plaintext
lib
├── main.dart                                       # アプリのエントリーポイント。最初に実行されるファイル
├── l10n                                            # 多言語対応用のARBファイルを格納するディレクトリ
│   ├── app_en.arb                                  # 英語翻訳ファイル　
│   └── app_ja.arb                                  # 日本語翻訳ファイル
└── src
    ├── core                                        # アプリ全体で共通的に利用される基盤コード
    │   ├── auth                                    # 認証関連（トークン管理・リフレッシュなど）
    │   │   ├── auth_guard.dart                     # GoRouter用ガード関数
    │   │   ├── auth_repository.dart                # ログイン・リフレッシュ処理
    │   │   ├── auth_state_notifier.dart            # ログイン状態を監視するProvider
    │   │   ├── token_interceptor.dart              # DioのInterceptorで自動付与・更新
    │   │   └── token_storage.dart                  # トークンの永続化（SharedPreferences）
    │   ├── config                                  # 環境設定やテーマ、共有設定など
    │   │   ├── app_config_provider.dart            # アプリ全体の設定をまとめて取得するプロバイダ
    │   │   ├── app_env.dart                        # 環境変数を定義するクラス
    │   │   ├── app_theme.dart                      # flex_color_schemeによるテーマ設定
    │   │   ├── locale_provider.dart                # アプリ全体のロケールを管理するプロバイダ
    │   │   └── theme_mode_provider.dart            # ダークモードなどテーマ切替の状態管理
    │   ├── exceptions                              # 共通の例外クラス定義
    │   │   └── app_exception.dart                  # APIエラーなどをまとめて扱う例外クラス
    │   ├── network                                 # 通信関連の設定やロギング
    │   │   ├── dio_interceptor.dart                # Dioの通信を監視するInterceptor
    │   │   └── logger_provider.dart                # loggerパッケージによるログ出力設定
    │   ├── router                                  # ルーティング（GoRouter）関連
    │   │   └── app_router.dart                     # ルート定義（画面遷移の設定）
    │   ├── storage                                 # 永続化関連（SharedPreferencesベースのキャッシュなど）
    │   │   ├── cache_manager.dart                  # キャッシュ共通クラス
    │   │   └── shared_preferences_provider.dart    # SharedPreferencesプロバイダ
    │   ├── ui                                      # 共通UI関連（エラーハンドリングなど）
    │   │   └── error_handler.dart                  # グローバルなエラーハンドリングUI
    │   ├── utils                                   # 共通のユーティリティ関数群（未実装 or 今後追加）
    │   └── widgets                                 # 汎用UI部品や画面
    │       ├── home_screen.dart                    # ホーム画面
    │       ├── not_found_screen.dart               # ルートが見つからない時の画面
    │       └── settings_screen.dart                # 設定画面
    ├── data                                        # データ層：APIやリポジトリの定義
    │   ├── datasource                              # API通信やデータ取得関連
    │   │   └── api_client.dart                     # Dioを使ったAPIクライアント
    │   ├── models                                  # 共通モデル定義（未実装 or 今後追加）
    │   └── repository                              # 共通リポジトリ定義（未実装 or 今後追加）
    └── features                                    # 各機能（画面単位）ごとのモジュール
        ├── auth                                    # 認証関連機能
        │   └── presentation                        # 画面(UI)層
        │       └── login_screen.dart               # ログイン画面のUI
        ├── sample_feature                          # サンプル用の機能
        │   ├── application                         # 状態管理・ビジネスロジック
        │   ├── data                                # データ取得処理（APIやDBアクセス）
        │   ├── domain                              # ドメインモデル・エンティティ定義
        │   └── presentation                        # 画面(UI)層
        │       └── sample_screen.dart              # サンプル画面のUI
        ├── splash                                  # スプラッシュ画面関連機能
        │   └── presentation                        # 画面(UI)層
        │       └── splash_screen.dart              # スプラッシュ画面のUI
        └── user                                    # ユーザー関連機能
            ├── application                         # 状態管理やNotifier
            │   └── user_notifier.dart              # ユーザーリスト管理のNotifier
            ├── data                                # データ層（モデルやリポジトリ）
            │   ├── address.dart                    # 住所モデル
            │   ├── user_model.dart                 # ユーザーモデル
            │   └── user_repository.dart            # ユーザー情報を扱うリポジトリ
            └── presentation                        # 画面(UI)層
                └── user_list_screen.dart           # ユーザー一覧画面のUI
```

---
