# Flutter Sample Project

Flutter開発のサンプルプロジェクトです。\
初学者から中級者まで、実践的なアプリ構成や開発環境の整備方法を学ぶことができます。

---

## 目次 (Table of Contents)

- [プロジェクト概要](#プロジェクト概要)
- [採用技術](#採用技術)
- [開発環境](#開発環境)
- [ディレクトリ構成](#ディレクトリ構成)
- [初期セットアップ](#初期セットアップ)
- [Git Hooks（コミット時 Lint 実行）](#git-hooksでコミット前にlintチェックを自動実行)
- [Lint設定](#lint設定)
- [GoRouter（型安全ルーティング）](#gorouterを使ったルーティング設定)
- [SharedPreferences 永続化](#sharedpreferences-の永続化設定)
- [テーマ設定（FlexColorScheme）](#テーマ設定flexcolorscheme)
- [多言語対応（Localization）](#多言語対応localization)
- [API通信デモ](#api通信デモuserlist)
- [通信エラーとロギング](#通信エラーとロギング改善)
- [共通エラーハンドリング](#共通エラーハンドリングsnackbar--dialog)
- [トークン認証（Bearer + Refresh）](#トークン認証対応bearer-token--自動リフレッシュ)
- [認証状態管理とルーティング制御](#認証状態管理とルーティング制御authguard--splashscreen)
- [APIキャッシュ対応](#apiキャッシュ対応sharedpreferencesベース)
- [コード生成コマンド](#コード生成コマンド)
- [このプロジェクトで学べること](#このプロジェクトで学べること)
- [今後の拡張案](#今後の拡張案)

## プロジェクト概要

このプロジェクトは、Flutterを用いたアプリ開発で役立つ構成・設定を体系的にまとめたテンプレートです。\
特に以下の技術スタックを採用し、実務でも通用する設計を意識しています。

### 採用技術

| 分類             | 使用技術                                                                                                                                                                                |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 状態管理           | [Riverpod](https://riverpod.dev) + [Flutter Hooks](https://pub.dev/packages/flutter_hooks)                                                                                          |
| ルーティング         | [GoRouter](https://pub.dev/packages/go_router) + [go\_router\_builder](https://pub.dev/packages/go_router_builder)                                                                  |
| 通信             | [Dio](https://pub.dev/packages/dio) + [pretty\_dio\_logger](https://pub.dev/packages/pretty_dio_logger)                                                                             |
| モデル生成          | [Freezed](https://pub.dev/packages/freezed) + [json\_serializable](https://pub.dev/packages/json_serializable)                                                                      |
| 環境変数           | [Envied](https://pub.dev/packages/envied)                                                                                                                                           |
| テーマ管理          | [Flex Color Scheme](https://pub.dev/packages/flex_color_scheme)                                                                                                                     |
| ログ             | [Logger](https://pub.dev/packages/logger)                                                                                                                                           |
| Lint / 静的解析    | [very\_good\_analysis](https://pub.dev/packages/very_good_analysis), [custom\_lint](https://pub.dev/packages/custom_lint), [riverpod\_lint](https://pub.dev/packages/riverpod_lint) |
| Flutterバージョン管理 | [FVM](https://fvm.app) (`3.35.7` 使用)                                                                                                                                                |

---

## 開発環境

| 項目          | 内容                        |
| ----------- | ------------------------- |
| IDE         | Visual Studio Code        |
| Flutter SDK | 管理: FVM / バージョン: 3.35.7   |
| Dart SDK    | 3.9.2                     |
| GitHub管理    | Git（`.gitkeep`で空ディレクトリ管理） |

---

## ディレクトリ構成

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

## 初期セットアップ

### 1️⃣ FVMによるFlutterバージョン指定

```bash
fvm use 3.35.7
```

### 2️⃣ 依存パッケージのインストール

```bash
fvm flutter pub get
```

---

## Git Hooksでコミット前にLintチェックを自動実行

このプロジェクトでは、コミット時に自動で `flutter analyze` と `dart format` チェックを実行する仕組みを導入しています。\
これにより、Lintエラーやフォーマット漏れを防ぎ、常にクリーンな状態でコードをコミットできます。

### セットアップ

```bash
chmod +x tool/hooks/pre-commit tool/setup_git_hooks.sh
./tool/setup_git_hooks.sh
```

これにより、Gitのフック設定が自動的に更新され、\
`tool/hooks/pre-commit` がリポジトリ全体で共有されます。

### 動作内容

- コミット前に以下を自動実行：
  - `flutter analyze`（静的解析）
  - `dart format --set-exit-if-changed`（フォーマットチェック）
- どちらかに問題がある場合、コミットは中断されます。

---

## Lint設定

### 利用パッケージ

- very\_good\_analysis
- custom\_lint
- riverpod\_lint

---

## GoRouterを使ったルーティング設定

本プロジェクトでは [GoRouter](https://pub.dev/packages/go_router) を利用し、アプリ全体の画面遷移を管理しています。\
さらに [go\_router\_builder](https://pub.dev/packages/go_router_builder) を導入し、アノテーションによる**型安全なルーティング定義**を実現しています。

### 主な特徴

- `@TypedGoRoute` アノテーションでルートを定義し、`build_runner` により自動生成。
- 各画面は `GoRouteData` を継承し、IDE補完で安全に遷移可能。
- `const SampleRoute().go(context)` のように記述でき、パス文字列を直接書く必要がありません。
- `routerProvider` により、`Riverpod` 経由で `GoRouter` インスタンスを提供します。

---

### 📘 TypedGoRouteの使用例

ルートごとにクラスを定義して、型安全な遷移を実現します。

```dart
// lib/src/core/router/app_router.dart

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

// 画面遷移例
const HomeRoute().go(context); // "/" に遷移
```

これにより、文字列ベースのルーティング記述を避けられ、IDE補完が有効になります。
IDEでルートクラスを補完することで、タイプミスやパス指定ミスを防げます。

---

### 🧩 RiverpodアノテーションによるGoRouter管理

`GoRouter` 設定を Riverpod のアノテーション構文（`@riverpod`）で定義。\
`routerProvider` が自動生成され、明示的な `Provider<GoRouter>` 記述が不要です。

---

## SharedPreferences の永続化設定

テーマモードなどの設定値を永続化するために、`SharedPreferences` をアプリ全体で共有する仕組みを導入しています。\
Riverpod のアノテーション構文（`@Riverpod(keepAlive: true)`）を使い、どのプロバイダからでも安全にアクセス可能です。

この構成により、`SharedPreferences` のインスタンスをアプリ全体で共有し、 I/O を最小化しつつテスト可能な形で永続化処理を行えます。

---

## テーマ設定（FlexColorScheme）

アプリ全体のデザインテーマは [FlexColorScheme](https://pub.dev/packages/flex_color_scheme) を利用して構築しています。
Material 3 対応で、ライト／ダーク／システムモードの切り替えに対応しています。

### 主なファイル構成

```plaintext
lib/src/core/config/
 ├── app_theme.dart           # テーマ定義（FlexColorScheme）
 └── theme_mode_provider.dart # テーマモードを管理するRiverpodプロバイダ
```

💡 `SharedPreferences` と連携し、ユーザーが選択したテーマモードを永続化しています。
アプリ起動時に前回のテーマ設定を自動的に復元します。

---

## 多言語対応（Localization）

本プロジェクトでは Flutter の公式ローカライズ機能（gen-l10n）を利用し、**lib/l10n + l10n.yaml** を用いた安定した多言語対応を実現しています。

### 📁 ディレクトリ構成

```plaintext
lib/
 └── l10n/
      ├── app_en.arb
      └── app_ja.arb
l10n.yaml
```

### 📝 l10n.yaml（プロジェクトルート）

```plaintext
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

### 🌐 ARB ファイル例

```json
app_en.arb:
{
  "@@locale": "en",
  "hello": "Hello",
  "login": "Login",
  "logout": "Logout"
}
```

```json
app_ja.arb:
{
  "@@locale": "ja",
  "hello": "こんにちは",
  "login": "ログイン",
  "logout": "ログアウト"
}
```

### ⚙️ コード生成

`fvm flutter gen-l10n`

ARB を編集した場合は再度コード生成が必要です。
ホットリロードでは翻訳が更新されないため、
アプリを一度完全に停止して再起動してください。

### 🏗 MaterialApp への組み込み

```dart
MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

### 🧩 翻訳の利用例

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.hello);
```

---

## API通信デモ（UserList）

[Dio](https://pub.dev/packages/dio) と [Riverpod](https://pub.dev/packages/flutter_riverpod) を組み合わせ、
外部APIからデータを取得してUIに表示する仕組みを実装しています。
以下は `https://jsonplaceholder.typicode.com/users` を利用したユーザー一覧取得サンプルです。

### 📁 構成例

```plaintext
lib/src/features/user/
  ├── data/
  │   ├── user_model.dart       # Freezedで定義したユーザーモデル
  │   └── user_repository.dart  # API呼び出し
  ├── application/
  │   └── user_notifier.dart    # 状態管理（ロード中・成功・エラー）
  └── presentation/
      └── user_list_screen.dart # 一覧表示画面
```

### 主なポイント

- `Dio` の共通インスタンスを `apiClientProvider` として提供。
- `Freezed` + `JsonSerializable` による型安全なモデル変換。
- `Riverpod` アノテーション（`@riverpod`）を活用した状態管理。
- 画面では `AsyncValue` による読み込み・エラー・成功表示を制御。

---

## 通信エラーとロギング改善

このプロジェクトでは、Dioを利用した通信基盤に共通エラーハンドリングとロギング処理を追加しています。
これにより、すべてのAPI通信で統一的にエラー管理とログ出力が可能になります。

---

### 📁 追加ファイル構成

```plaintext
lib/src/core/
 ├── exceptions/
 │    └── app_exception.dart        # 共通例外クラス
 └── network/
      ├── dio_interceptor.dart      # 共通Dioインターセプタ
      └── logger_provider.dart      # 環境別ログ出力用Loggerプロバイダ
```

---

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 安定性 | すべてのAPIエラーを共通で処理 |
| デバッグ効率 | 環境別ログ制御でノイズを削減 |
| 拡張性 | トークン更新やリトライ機能の追加が容易 |
| テスト容易性 | AppExceptionを使ったモックが可能 |

---

この改善により、通信処理の信頼性とデバッグ性が大幅に向上します。

---

## 共通エラーハンドリング（Snackbar & Dialog）

アプリ全体で例外を統一的に処理するために、`ErrorHandler` クラスを追加します。  
これにより、軽いエラーは **Snackbar**、致命的なエラーは **Dialog** で表示できます。

---

### 📁 ファイル構成

```plaintext
lib/src/core/ui/
 └── error_handler.dart
```

---

### 💡 使い分け例

#### 軽い通信エラー（Snackbar）

```dart
ErrorHandler.showSnackBar(context, e);
```

#### 致命的なエラー（Dialog）

```dart
await ErrorHandler.showDialogError(context, e);
```

---

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 柔軟性 | 状況に応じてSnackbarとDialogを使い分け可能 |
| 再利用性 | どの画面からも `ErrorHandler` 経由で統一的に呼び出せる |
| メンテナンス性 | メッセージロジックを一元管理 |
| UX向上 | アプリ全体で一貫したエラー体験を提供 |

---

これで、すべての画面で例外を安全かつ一貫してユーザーに伝えられるようになります。

---

## トークン認証対応（Bearer Token + 自動リフレッシュ）

このプロジェクトでは、API通信にBearerトークン認証を追加し、トークンの自動付与および自動リフレッシュ処理を実装しています。
これにより、ログイン後のすべての通信で認証ヘッダーを自動的に付与し、有効期限切れ時に再取得を行います。

---

### 📁 ファイル構成

```plaintext
lib/src/core/auth/
 ├── token_storage.dart       # トークンの永続化（SharedPreferences）
 ├── auth_repository.dart     # ログイン・リフレッシュ処理
 └── token_interceptor.dart   # DioのInterceptorで自動付与・更新
```

---

### 🧩 Dioへの組み込み順序（重要）

Interceptorの登録順序は以下の通りにしてください👇

```dart
dio.interceptors.add(ref.read(tokenInterceptorProvider)); // ① トークン付与・リフレッシュ
dio.interceptors.add(ref.read(dioInterceptorProvider));   // ② ログ出力・エラーハンドリング
```

#### 💡 理由

| 順番 | 説明 |
|------|------|
| ① tokenInterceptor | リクエスト前に認証ヘッダーを追加・401検知でリフレッシュ |
| ② dioInterceptor | 通信全体のログ・例外処理を担当（最終層で処理） |

> 順番を逆にすると、ログにトークンが含まれなかったり、401エラー時の自動リフレッシュが動作しないことがあります。

---

### ✅ 動作確認手順

1. `/auth/login` に有効なユーザー情報をPOSTしてログイン  
2. `SharedPreferences` にトークンが保存されていることを確認  
3. 他のAPI通信で `Authorization` ヘッダーが自動付与されることを確認  
4. トークン失効時に `/auth/refresh` が自動呼び出されることを確認  

---

この構成により、アプリ全体で安全かつ自動化された認証フローを実現できます。

---

### 💡 補足

- `authRepositoryProvider` を通じてログインAPIを呼び出し、トークンを保存します。  
- 以降のAPI通信では `tokenInterceptorProvider` により自動で認証ヘッダーが付与されます。  
- トークンの有効期限が切れると自動的にリフレッシュ処理が走ります。

---

## 認証状態管理とルーティング制御（AuthGuard + SplashScreen）

このプロジェクトでは、`AuthStateNotifier` と `GoRouter` の `redirect` 機能を組み合わせ、  
ログイン状態に応じて画面遷移を自動制御しています。  
さらに、状態判定中のチラつきを防ぐために `SplashScreen` を導入しています。

---

### 📁 追加ファイル構成

```plaintext
lib/src/core/auth/
 ├── auth_state_notifier.dart   # ログイン状態を監視するProvider
 ├── auth_guard.dart            # GoRouter用ガード関数
 └── token_storage.dart         # トークン保存クラス（既存）

lib/src/features/splash/
 └── presentation/
     └── splash_screen.dart     # 起動時のローディング画面
```

---

💡  
`SplashScreen` はアプリ起動直後に一瞬だけ表示され、  
認証状態の判定が終わるまでルーティングのチラつきを防ぎます。

---

### 🧪 動作フロー

```plaintext
アプリ起動
   ↓
SplashScreen表示（認証状態チェック）
   ↓
トークン保持あり → HomeRoute("/")へ
トークンなし → LoginRoute("/login")へ
```

---

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 状態管理 | Riverpodでログイン状態を明示的に管理 |
| 自動遷移 | GoRouterの`redirect`で状態に応じてルート切替 |
| UX | SplashScreenでチラつきのない自然な遷移 |
| 再利用性 | どのアプリでも流用可能な汎用的構成 |

---

この構成により、ログイン状態を常に監視し、  
起動時・ログイン時・ログアウト時の画面遷移を自動化できます。

---

## APIキャッシュ対応（SharedPreferencesベース）

このプロジェクトでは、APIレスポンスを一定時間キャッシュして再利用することで、通信効率とユーザー体験を向上させています。
キャッシュは `SharedPreferences` を用いて実現しており、外部パッケージを追加せずに軽量に動作します。

---

### 📁 追加ファイル構成

```plaintext
lib/src/core/storage/
 ├── cache_manager.dart        # キャッシュ共通クラス
 └── cache_provider.dart       # Riverpodプロバイダ

lib/src/features/user/data/
 └── user_repository.dart      # fetchUsersをキャッシュ対応化
```

---

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 高速化 | 2回目以降はAPI通信なしで即表示 |
| オフライン対応 | ネットワーク切断時でも前回データを利用可能 |
| シンプル | パッケージ追加不要・メンテナンス性が高い |

---

### 🔄 Pull to Refreshによるキャッシュ更新例

以下の例では、`RefreshIndicator` を利用してユーザーがスワイプ操作で最新データを取得します。

```dart
// lib/src/features/user/presentation/user_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    Future<void> onRefresh() async {
      // API再取得（キャッシュ無視）
      await ref
          .read(userNotifierProvider.notifier)
          .fetchUsers(forceRefresh: true);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: users.when(
        data: (list) => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) =>
                ListTile(title: Text(list[i].name)),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorUnknown)),
      ),
    );
  }
}
```

### 💡 補足

- `fetchUsers(forceRefresh: true)` によってキャッシュをスキップしてAPIを再取得します。  
- キャッシュ層 (`CacheManager`) に `clear()` を追加してから再保存することで、常に最新データを反映。  
- オフライン環境では前回キャッシュを自動で使用し、ユーザー体験を損なわずに動作します。

---

## コード生成コマンド

### 環境の切り替え、設定値変更

コード生成時に使用する `.env` ファイルを環境ごとに切り替えることができます。以下のコマンドを使用して、対象の環境設定に合わせて生成してください。

#### Local環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
```

#### Dev環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.dev"
```

#### Staging環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.stg"
```

#### Production環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.prod"
```

---

### 通常のコード生成

#### 都度実行する場合

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

#### 監視モードで実行する場合

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

---

### ネイティブ部分の環境による切り替え

## iOS

`ios/scripts/extract_dart_defines.sh` をPreActionsとして実行することで `.env` ファイルから値を取得します。  
取得した値は `ios/Runner/Info.plist` や `ios/Runner.xcodeproj/project.pbxproj` 内で `$(APP_NAME)` のように参照できます。

### Android

`android/app/build.gradle.kts` 内で `.env` ファイルから値を取得し、`dartDefines["APP_NAME"]` のように参照できます。  
`resValue("string", "app_name", dartDefines["APP_NAME"] ?: "Flutter Sample")` のようにすることで、`android/app/src/main/AndroidManifest.xml` 内で `@string/app_name` のように参照できます。

---

### 💡 補足：再生成が必要なタイミング

| 状況 | コード生成の要否 |
|------|----------------|
| 環境（.env）を切り替えた | 🔁 Envied再生成が必要 |
| モデル（Freezed / JsonSerializable）を更新した | ✅ 通常生成のみでOK |
| `.env` の値を修正した | 🔁 Envied再生成が必要 |
| コードのみ変更した | 🚫 Envied不要 |

**ポイント:**

- Enviedは環境変数をビルド時に暗号化して生成するため、環境を切り替えた場合や`.env`の値を変更した場合にのみ再生成が必要です。
- FreezedやJsonなど、通常のコード変更に関しては通常の`build_runner`実行で十分です。

---

## このプロジェクトで学べること

このサンプルプロジェクトを通して、以下の技術や設計手法を体系的に学ぶことができます。

| 分野 | 学べる内容 |
|------|-------------|
| 🧠 状態管理 | Riverpod（アノテーションベース）によるスケーラブルな構成 |
| 🧭 ルーティング | GoRouter + go_router_builder による型安全なルート設計 |
| 🌐 通信 | Dio + Interceptorによる共通通信層の設計 |
| 🔒 認証 | Bearerトークン + 自動リフレッシュ構成 |
| 💾 データ保持 | SharedPreferencesを用いたキャッシュ・テーマ・トークン永続化 |
| 🧰 コード生成 | build_runner + Enviedによる環境切替対応 |
| 🎨 UI | FlexColorSchemeによるテーマ設定と永続化 |
| 🧩 Lint | very_good_analysis + custom_lint + riverpod_lintの実用設定 |
| 🚀 開発効率 | FVM + VSCode設定 + Git Hooks で統一開発環境を構築 |

---

## 今後の拡張案

| カテゴリ | 拡張内容 |
|-----------|-----------|
| 💡 認証 | `flutter_secure_storage` を使った安全なトークン保存、OAuth対応 |
| 🧱 データ | HiveやIsarを使った構造化キャッシュ、DB同期処理 |
| 📱 UI | エラーハンドリング・リトライUI、スナックバー通知、リフレッシュインジケータ |
| 🧩 モジュール構成 | Feature単位でのドメイン分割・モジュラリティ対応 |
| 🧠 テスト | Unit / Widget / Integration テスト導入 |
| ☁️ API | GraphQL・gRPCなど別通信方式への拡張 |
| 🧰 CI/CD | GitHub Actionsによる自動テスト・デプロイ |

---

📘 **このREADMEは学習・実務両対応のFlutterアプリ構成ガイドとして活用できます。**  
チーム開発・教育・個人学習など、目的に応じて自由に拡張してください。
