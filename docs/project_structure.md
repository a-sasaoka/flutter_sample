# ディレクトリ構成

以下はプロジェクトの主要ディレクトリとファイルの構成です。
それぞれの役割をコメントで補足しています。
自動生成ファイルは原則除外しています。

```plaintext
flutter_sample
├── .end.dev                                                    # 環境毎の設定ファイル（開発環境用。Gitでは管理しない）
├── .end.local                                                  # 環境毎の設定ファイル（ローカル用。Gitでは管理しない）
├── .end.prod                                                   # 環境毎の設定ファイル（本番環境用。Gitでは管理しない）
├── .end.stg                                                    # 環境毎の設定ファイル（ステージング環境用。Gitでは管理しない）
└── lib
    ├── firebase_options_dev.dart                               # FlutterFire CLIで自動生成されるファイル（開発環境用。Gitでは管理しない）
    ├── firebase_options_local.dart                             # FlutterFire CLIで自動生成されるファイル（ローカル用。Gitでは管理しない）
    ├── firebase_options_prod.dart                              # FlutterFire CLIで自動生成されるファイル（本番環境用。Gitでは管理しない）
    ├── firebase_options_stg.dart                               # FlutterFire CLIで自動生成されるファイル（ステージング環境用。Gitでは管理しない）
    ├── main.dart                                               # アプリのエントリーポイント。最初に実行されるファイル
    ├── l10n                                                    # 多言語対応用のARBファイルを格納するディレクトリ
    │   ├── app_en.arb                                          # 英語翻訳ファイル　
    │   └── app_ja.arb                                          # 日本語翻訳ファイル
    └── src
        ├── core                                                # アプリ全体で共通的に利用される基盤コード
        │   ├── analytics                                       # イベント計測関連
        │   │   ├── analytics_event.dart                        # イベント定義
        │   │   └── analytics_service.dart                      # イベント送信サービス
        │   ├── auth                                            # 認証関連（トークン管理・リフレッシュなど）
        │   │   ├── auth_guard.dart                             # 一般的なトークンを用いた認証状態を監視するGuard
        │   │   ├── auth_repository.dart                        # 一般的なトークンを用いたログイン・トークン処理を行うリポジトリ
        │   │   ├── auth_state_notifier.dart                    # 一般的なトークンを用いた認証状態を管理するStateNotifier
        │   │   ├── base_auth_guard.dart                        # 認証状態に応じたリダイレクト先を判定する共通ヘルパー
        │   │   ├── firebase_auth_guard.dart                    # Firebase Authenticationを用いた認証状態を監視するGuard
        │   │   ├── firebase_auth_repository.dart               # Firebase Authenticationを用いた認証リポジトリ
        │   │   ├── firebase_auth_state_notifier.dart           # Firebase Authenticationの認証状態を管理するStateNotifier
        │   │   ├── token_interceptor.dart                      # DioのInterceptorでトークンを自動付与・更新
        │   │   └── token_storage.dart                          # トークンの永続化（SharedPreferences）
        │   ├── config                                          # 環境設定やテーマ、共有設定など
        │   │   ├── app_config_provider.dart                    # アプリ全体の設定をまとめて取得するプロバイダ
        │   │   ├── app_env.dart                                # 環境変数を定義するクラス
        │   │   ├── app_theme.dart                              # flex_color_schemeによるテーマ設定
        │   │   ├── firebase_options.dart                       # 環境毎のFirebaseOptionsの切り替えを行う
        │   │   ├── flavor_provider.dart                        # Flavorを扱うProvider
        │   │   ├── locale_provider.dart                        # アプリ全体のロケールを管理するプロバイダ
        │   │   └── theme_mode_provider.dart                    # ダークモードなどテーマ切替の状態管理
        │   ├── exceptions                                      # 共通の例外クラス定義
        │   │   └── app_exception.dart                          # APIエラーなどをまとめて扱う例外クラス
        │   ├── network                                         # 通信関連の設定やロギング
        │   │   ├── dio_interceptor.dart                        # Dioの通信を監視するInterceptor
        │   │   └── logger_provider.dart                        # loggerパッケージによるログ出力設定
        │   ├── router                                          # ルーティング（GoRouter）関連
        │   │   └── app_router.dart                             # ルート定義（画面遷移の設定）
        │   ├── storage                                         # 永続化関連（SharedPreferencesベースのキャッシュなど）
        │   │   ├── cache_manager.dart                          # キャッシュ共通クラス
        │   │   └── shared_preferences_provider.dart            # SharedPreferencesプロバイダ
        │   ├── ui                                              # 共通UI関連（エラーハンドリングなど）
        │   │   └── error_handler.dart                          # グローバルなエラーハンドリングUI
        │   ├── utils                                           # 共通のユーティリティ関数群
        │   └── widgets                                         # 汎用UI部品や画面
        │       ├── home_screen.dart                            # ホーム画面
        │       ├── not_found_screen.dart                       # ルートが見つからない時の画面
        │       └── settings_screen.dart                        # 設定画面
        ├── data                                                # データ層：APIやリポジトリの定義
        │   └── datasource                                      # API通信やデータ取得関連
        │       │   └── api_client.dart                         # Dioを使ったAPIクライアント
        │       ├── models                                      # 共通モデル定義
        │       └── repository                                  # 共通リポジトリ定義
        └── features                                            # 各機能（画面単位）ごとのモジュール
            ├── auth                                            # 認証関連機能
            │   └── presentation                                # 画面(UI)層
            │       ├── firebase_email_verification_screen.dart # Firebaseでメール認証の確認・再送信を行う画面
            │       ├── firebase_login_screen.dart              # Firebase版ログイン画面
            │       ├── firebase_reset_password_screen.dart     # Firebase版パスワードのリセットメールを送信する画面
            │       ├── firebase_sign_up_screen.dart            # Firebase版サインアップ画面
            │       └── login_screen.dart                       # ログイン画面
            ├── sample_feature                                  # サンプル用の機能
            │   ├── application                                 # 状態管理・ビジネスロジック
            │   ├── data                                        # データ取得処理（APIやDBアクセス）
            │   ├── domain                                      # ドメインモデル・エンティティ定義
            │   └── presentation                                # 画面(UI)層
            │       └── sample_screen.dart                      # サンプル画面
            ├── splash                                          # スプラッシュ画面関連機能
            │   └── presentation                                # 画面(UI)層
            │       └── splash_screen.dart                      # スプラッシュ画面
            └── user                                            # ユーザー関連機能
                ├── application                                 # 状態管理やNotifier
                │   └── user_notifier.dart                      # ユーザーリスト管理のNotifier
                ├── data                                        # データ層（モデルやリポジトリ）
                │   ├── address.dart                            # 住所モデル
                │   ├── user_model.dart                         # ユーザーモデル
                │   └── user_repository.dart                    # ユーザー情報を扱うリポジトリ
                └── presentation                                # 画面(UI)層
                    └── user_list_screen.dart                   # ユーザー一覧画面
```

---
