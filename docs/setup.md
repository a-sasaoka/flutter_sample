# 初期セットアップ

## 1️⃣ 前提ツールのインストール（未導入の場合）

Flutterのバージョン管理ツール「FVM」、Firebaseの操作に必要な「Firebase CLI (`firebase-tools`)」と「FlutterFire CLI」を使用します。

```bash
# FVMが未インストールの場合はインストール (macOS / Homebrew)
brew tap leoafarias/fvm
brew install fvm

# Firebase CLI が未インストールの場合はインストール
# (macOS/Linux推奨の自動インストールスクリプト)
curl -sL https://firebase.tools | bash
# ※Node.js環境がある場合は `npm install -g firebase-tools` でも可能です。

# Firebase CLI にログイン
firebase login

# FlutterFire CLIが未インストールの場合はインストール
dart pub global activate flutterfire_cli
```

## 2️⃣ FVMで指定されているバージョンのFlutterを利用可能にする

```bash
fvm use
```

## 3️⃣ 依存パッケージのインストール

```bash
fvm flutter pub get
```

※ macOS環境でiOSアプリをビルドする場合は、あわせて CocoaPods のインストールも実行してください。

```bash
cd ios
pod install
cd ..
```

## 4️⃣ 環境設定ファイルの準備

本プロジェクトでは、**「公開設定（JSON）」**と**「秘匿情報（.env）」**を使い分けています。

### 1. 公開設定 (Git管理対象)

`config/flavor_*.json` を確認し、必要に応じて値を修正してください。
（通常はデフォルトのままで動作しますが、APIのURLなどを変更したい場合に編集します）

### 2. 秘匿情報 (Git管理外)

`env.example` をコピーして、以下の4ファイルを作成します。

- `.env.local`
- `.env.dev`
- `.env.stg`
- `.env.prod`

各ファイルには、各自の環境に応じた以下の値を設定してください。

| 項目                        | 説明                                            |
| :-------------------------- | :---------------------------------------------- |
| `DEBUG_TOKEN`               | Firebase App Check のデバッグトークン           |
| `GOOGLE_REVERSED_CLIENT_ID` | iOS の URL Scheme 設定に必要な逆クライアント ID |

## 5️⃣ Firebase利用準備

1. Firebase Consoleにてプロジェクトを作成し、`pubspec.yaml` の `flavorizr` セクションに記載されている `applicationId` / `bundleId` と一致するようにアプリを追加します。

2. Firebase コンソールから設定ファイルをダウンロードし、以下の**Flavor別のディレクトリ**に配置してください。
   - **Android**: `android/app/src/{flavor}/google-services.json`
   - **iOS**: `ios/Runner/Firebase/{flavor}/GoogleService-Info.plist`

> 💡 **自動切り替え**: 配置したファイルは、ビルド時に選択された Flavor に応じた自動的に適用されます。

3. `flutterfire configure` 等で生成された `lib/firebase_options.dart` は、環境ごとに `lib/firebase_options_local.dart` のようにリネームして配置してください。

## 6️⃣ アプリの実行・デバッグ

### VS Code から実行（推奨）

`.vscode/launch.json` に各 Flavor の設定が登録されています。

1. 「実行とデバッグ」タブ（`Ctrl+Shift+D`）を開く。
2. 上部のプルダウンから `flutter_sample (local)` 等、実行したい環境を選択。
3. `F5` キーでデバッグ開始。

### コマンドラインから実行

以下の形式で実行します。

```bash
# dev環境の実行例
fvm flutter run -t lib/main_dev.dart --flavor dev --dart-define-from-file=config/flavor_dev.json --dart-define-from-file=.env.dev
```

---

## 7️⃣ コード生成コマンドの実行

モデルの定義や Riverpod プロバイダを変更した場合は、以下のコマンドを実行します。

```bash
# 一括生成
fvm dart run build_runner build
```

---

## Git Hooksでコミット前にLintチェックを自動実行

このプロジェクトでは、コミット時に自動で `flutter analyze` と `dart format` チェックを実行する仕組みを導入しています。

### セットアップ

```bash
chmod +x tool/hooks/pre-commit tool/setup_git_hooks.sh
./tool/setup_git_hooks.sh
```
