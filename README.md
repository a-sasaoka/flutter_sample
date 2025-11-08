# Flutter Sample Project

Flutter開発のサンプルプロジェクトです。\
初学者から中級者まで、実践的なアプリ構成や開発環境の整備方法を学ぶことができます。

---

## 🚀 プロジェクト概要

このプロジェクトは、Flutterを用いたアプリ開発で役立つ構成・設定を体系的にまとめたテンプレートです。\
特に以下の技術スタックを採用し、実務でも通用する設計を意識しています。

### 🧠 採用技術

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

## ⚙️ 開発環境

| 項目          | 内容                        |
| ----------- | ------------------------- |
| IDE         | Visual Studio Code        |
| Flutter SDK | 管理: FVM / バージョン: 3.35.7   |
| Dart SDK    | 3.9.2                     |
| GitHub管理    | Git（`.gitkeep`で空ディレクトリ管理） |

---

## 📁 ディレクトリ構成

```bash
lib/
└── src/
    ├── core/                     # 共通設定・ルーター・ユーティリティ
    │   ├── config/               # 定数・テーマ設定
    │   ├── router/               # GoRouter関連
    │   ├── exceptions/           # 共通例外
    │   ├── utils/                # 共通ユーティリティ
    │   └── widgets/              # 共通Widget
    ├── data/                     # 共通データアクセス層
    │   ├── models/               # Freezedモデル
    │   ├── repository/           # Repository層
    │   └── datasource/           # Dio等のデータソース層
    ├── features/                 # 機能ごとのモジュール
    │   └── sample_feature/
    │       ├── presentation/     # UI層
    │       ├── application/      # Provider・状態管理層
    │       ├── domain/           # Entity・ビジネスロジック
    │       └── data/             # 機能専用データアクセス
    └── main.dart                 # エントリーポイント
```

---

## 🧱 初期セットアップ

### 1️⃣ FVMによるFlutterバージョン指定

```bash
fvm use 3.35.7
```

### 2️⃣ 依存パッケージのインストール

```bash
flutter pub get
```

### 3️⃣ ディレクトリ構成を自動生成（スクリプト実行）

```bash
chmod +x setup_project_structure.sh
./setup_project_structure.sh
```

---

## 🧩 Git Hooksでコミット前にLintチェックを自動実行

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

## 🧩 GoRouterを使ったルーティング設定

本プロジェクトでは [GoRouter](https://pub.dev/packages/go_router) を利用し、アプリ全体の画面遷移を管理しています。\
さらに [go\_router\_builder](https://pub.dev/packages/go_router_builder) を導入し、アノテーションによる**型安全なルーティング定義**を実現しています。

### 主な特徴

- `@TypedGoRoute` アノテーションでルートを定義し、`build_runner` により自動生成。
- 各画面は `GoRouteData` を継承し、IDE補完で安全に遷移可能。
- `const SampleRoute().go(context)` のように記述でき、パス文字列を直接書く必要がありません。
- `routerProvider` により、`Riverpod` 経由で `GoRouter` インスタンスを提供します。

---

### 🧩 RiverpodアノテーションによるGoRouter管理

`GoRouter` 設定を Riverpod のアノテーション構文（`@riverpod`）で定義。\
`routerProvider` が自動生成され、明示的な `Provider<GoRouter>` 記述が不要です。

---

## 🧩 SharedPreferences の永続化設定

テーマモードなどの設定値を永続化するために、`SharedPreferences` をアプリ全体で共有する仕組みを導入しています。\
Riverpod のアノテーション構文（`@Riverpod(keepAlive: true)`）を使い、どのプロバイダからでも安全にアクセス可能です。

この構成により、`SharedPreferences` のインスタンスをアプリ全体で共有し、 I/O を最小化しつつテスト可能な形で永続化処理を行えます。

---

## 🎨 テーマ設定（FlexColorScheme）

アプリ全体のデザインテーマは [FlexColorScheme](https://pub.dev/packages/flex_color_scheme) を利用して構築しています。
Material 3 対応で、ライト／ダーク／システムモードの切り替えに対応しています。

### 主なファイル構成

```bash
lib/src/core/config/
 ├── app_theme.dart           # テーマ定義（FlexColorScheme）
 └── theme_mode_provider.dart # テーマモードを管理するRiverpodプロバイダ
```

💡 `SharedPreferences` と連携し、ユーザーが選択したテーマモードを永続化しています。
アプリ起動時に前回のテーマ設定を自動的に復元します。

---

## 🌐 API通信デモ（UserList）

[Dio](https://pub.dev/packages/dio) と [Riverpod](https://pub.dev/packages/flutter_riverpod) を組み合わせ、
外部APIからデータを取得してUIに表示する仕組みを実装しています。
以下は `https://jsonplaceholder.typicode.com/users` を利用したユーザー一覧取得サンプルです。

### 📁 構成例

```bash
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

## 🧩 Lint設定

### 利用パッケージ

- very\_good\_analysis
- custom\_lint
- riverpod\_lint

---

## 🧰 コード生成コマンド

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
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 監視モードで実行する場合

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

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
