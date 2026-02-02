# 初期セットアップ

このドキュメントを上から順に実行すれば、新規プロジェクトを作成できる構成にしています。
既存プロジェクトのセットアップにも同じ流れで使えます。

---

## 前提条件

- FVM がインストール済み（[インストールガイド](https://fvm.app/documentation/getting-started/installation?utm_source=openai)）
- Flutter/Dart バージョンは **Flutter 3.35.7 / Dart 3.9.2**
- Firebase を使う場合は Firebase Console にアクセスできること（この後の手順でプロジェクト作成を行います）

---

## 新規 Flutter プロジェクト作成

```bash
fvm install 3.35.7
fvm use 3.35.7
fvm flutter create --org jp.example your_app
cd your_app
```

### ここで決める項目

- `your_app` : プロジェクト名（フォルダ名/パッケージ名の基点）
- `--org jp.example` : Android の applicationId / iOS の bundleId のベース
  - このリポジトリでは最終的な識別子は `APP_ID` で決まるため、`--org` は初期作成時の仮値でも問題ありません。
  - ストア公開や Firebase 連携を始める前に、`.env` の `APP_ID` を正式な値に確定してください。

---

## ベース設定の反映（このリポジトリからコピー）

このリポジトリを参照し、以下を**新規プロジェクトへコピー**します。

### 必須（初期構成を再現するために最低限必要）

- `analysis_options.yaml`
- `devtools_options.yaml`
- `env.example`
- `l10n.yaml`
- `tool/`（Git Hooks スクリプト）
- `lib/`（アプリ構成のベース）

### 推奨（品質と運用を揃える）

- `pubspec.yaml` の dependencies / dev_dependencies 定義
- `docs/`（自分のプロジェクト用に更新）
- `.gitignore`（必要に応じて比較・差分反映）

---

## pubspec.yaml の依存関係を追加

このリポジトリの `pubspec.yaml` を参照して、依存を追加します。

主な追加対象:

- 状態管理: Riverpod / Hooks
- ルーティング: GoRouter + go_router_builder
- 通信: Dio + PrettyDioLogger
- モデル生成: Freezed + JsonSerializable
- 環境変数: Envied
- Firebase: core / analytics / crashlytics

追加後に依存取得:

```bash
fvm flutter pub get
```

---

## lib 構成を反映

このリポジトリの `lib/` をベースに、以下を揃えます。

- `lib/main.dart`
- `lib/firebase_options.dart`
- `lib/l10n/`（多言語ファイル）
- `lib/src/core/`（共通基盤）
- `lib/src/features/`（機能単位）

ポイント:

- `lib/firebase_options.dart` は **環境変数参照を前提に修正済み**です。
- ルーティング構成は `lib/src/core/router/app_router.dart` を起点に整理します。

---

## 環境変数の設定（Envied）

1. `env.example` をコピーして `.env.*` を作成します。

例:

```bash
cp env.example .env.local
```

`.env.*` はプロジェクト直下に置き、`.env.local` / `.env.dev` / `.env.stg` / `.env.prod` などの命名で管理します。

1. 各環境に合わせて値を編集します。

代表的なキー:

- `APP_NAME`, `APP_ID`
- `BASE_URL`
- `FIREBASE_*`

### 値の取得先と例

| キー | 取得先 | 例 |
| --- | --- | --- |
| `APP_NAME` | アプリ表示名 | `Sample App` |
| `APP_ID` | アプリ識別子（Android applicationId / iOS bundleId） | `jp.example.sample` |
| `BASE_URL` | API のベース URL | `https://api.example.com` |
| `FIREBASE_ANDROID_API_KEY` | Firebase Console → Project settings → Android アプリ | `AIza...` |
| `FIREBASE_ANDROID_APP_ID` | Firebase Console → Project settings → Android アプリ | `1:1234567890:android:abcdef...` |
| `FIREBASE_ANDROID_MSG_SENDER_ID` | Firebase Console → Project settings → General | `1234567890` |
| `FIREBASE_ANDROID_PROJECT_ID` | Firebase Console → Project settings → General | `your-project-id` |
| `FIREBASE_ANDROID_STORAGE_BUCKET` | Firebase Console → Project settings → General | `your-project-id.appspot.com` |
| `FIREBASE_IOS_API_KEY` | Firebase Console → Project settings → iOS アプリ | `AIza...` |
| `FIREBASE_IOS_APP_ID` | Firebase Console → Project settings → iOS アプリ | `1:1234567890:ios:abcdef...` |
| `FIREBASE_IOS_MSG_SENDER_ID` | Firebase Console → Project settings → General | `1234567890` |
| `FIREBASE_IOS_PROJECT_ID` | Firebase Console → Project settings → General | `your-project-id` |
| `FIREBASE_IOS_STORAGE_BUCKET` | Firebase Console → Project settings → General | `your-project-id.appspot.com` |
| `FIREBASE_IOS_BUNDLE_ID` | iOS の bundleId | `jp.example.sample` |

1. Envied 生成を実行します。

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
```

---

## ネイティブへの反映（dart-define）

このプロジェクトは `APP_ID` / `APP_NAME` などを **dart-define 経由でネイティブに渡す**設計です。  
そのため、起動時に `.env` の値を dart-define に反映させる必要があります。

### 反映方法（開発時）

以下のコマンドで起動します（`.env.local` を使う例）:

```bash
fvm flutter run --dart-define-from-file=.env.local
```

> `.env` の値を変更した場合は Envied の再生成が必要です。  
> 詳細な仕組みは [docs/code_generation.md](code_generation.md) を参照してください。

---

## Firebase の設定

### 1. Firebase プロジェクトとアプリ登録

1. Firebase Console で「プロジェクト」を作成  
   - プロジェクトは **アプリ運用の箱**。ここに Android / iOS アプリを登録する。
2. Firebase Console で Android / iOS アプリを追加  
   - **applicationId / bundleId** は `.env` の `APP_ID` と一致させる。

### 2. FlutterFire CLI で設定ファイルを生成

1. FlutterFire CLI を導入  
2. `fvm dart pub global run flutterfire_cli configure` を実行して、`firebase.json` と設定ファイルを生成

### 3. 設定ファイルの配置と差し替え

1. `google-services.json` と `GoogleService-Info.plist` を配置  
2. `lib/firebase_options.dart` は **このリポジトリの実装へ差し替え**（Envied を使うため）

> **重要**: `APP_ID`（.env）と Firebase に登録する ID は必ず一致させてください。  
> ここがずれると Firebase が初期化できません。

### FlutterFire CLI の具体例

- CLI を導入:

```bash
fvm dart pub global activate flutterfire_cli
```

- 設定の生成とログイン（初回のみ）:

```bash
fvm dart pub global run flutterfire_cli configure \
  --project=your-project-id \
  --android-package-name=jp.example.your_app \
  --ios-bundle-id=jp.example.your_app
```

- 実行時にブラウザが開き、Google アカウントでログインします。
- 既に `firebase.json` がある場合は再利用確認が出るため、ログイン画面が出ないことがあります。

> 出力された `lib/firebase_options.dart` は、Envied を使うために **このリポジトリの実装へ差し替え**ます。

#### 差し替え手順（コピー元 / コピー先）

1. `flutterfire configure` 実行後に作成されるファイル  
   - 生成先: `lib/firebase_options.dart`（新規プロジェクト側）
2. このリポジトリの Envied 対応版をコピー  
   - コピー元: `lib/firebase_options.dart`（このリポジトリ）
   - コピー先: `lib/firebase_options.dart`（新規プロジェクト）

#### 内容の差し替えポイント

- 生成版は `FirebaseOptions(...)` に **固定値**が埋め込まれる
- Envied 対応版は **`.env` の値を参照**して `FirebaseOptions(...)` を組み立てる

> つまり「生成版を捨てて、Envied 参照版を使う」という置き換えになります。

#### 設定ファイルの配置先

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### 設定ファイルの運用

- このプロジェクトでは各種設定値（APIキーなど秘匿情報含む）は **プライベートリポジトリで管理**します。
- それ以外のソースコードやドキュメントは **パブリックリポジトリ**で管理します。
- プライベート側はアクセス権管理が必須です。必要最小限の権限に限定し、外部に公開しないようにします。

Crashlytics / Analytics の設定詳細は以下を参照:

- `docs/crashlytics.md`
- `docs/analytics.md`

---

## コード生成（GoRouter / Riverpod / Freezed）

初回は必ずコード生成を実行します。

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

---

## 起動確認

```bash
fvm flutter run --dart-define-from-file=.env.local
```

> このプロジェクトでは `.env.*` を反映するため、通常は `--dart-define-from-file` を付けて起動します。  
> 例: `fvm flutter run --dart-define=FLUTTER_ENV=local --dart-define-from-file=.env.local`  
> VS Code の「Local」構成で起動すると同じ設定が適用されます。

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

- very_good_analysis
- custom_lint
- riverpod_lint

---
