# コード生成と環境切り替え

本プロジェクトでは、ボイラープレート（定型コード）の削減と型安全性の向上のため、強力なコード生成ツール群を活用しています。

## 📦 コード生成の対象パッケージ

以下のパッケージを利用してコードを自動生成（`*.g.dart`, `*.freezed.dart`）しています。
対象となるファイルを変更した場合や、新たにプロジェクトをクローンした直後は、必ずコード生成コマンドを実行してください。

- **Riverpod Generator**: 状態管理のプロバイダ生成
- **Freezed / json_serializable**: イミュータブルなデータモデルとJSONパース処理
- **GoRouter Builder**: `@TypedGoRoute` による型安全なルーティング定義
- **Envied**: `.env` ファイルからの秘匿情報（デバッグトークン等）の生成
- **Drift (drift_dev)**: データベースのテーブル定義とクエリコードの生成

---

## ⚙️ 環境の切り替えと実行コマンド

本プロジェクトでは、環境設定（Flavor）の切り替えに Flutter 標準の `--dart-define-from-file` を採用しています。

### 実行コマンドの構成

実行時には、**「対象の Flavor 用 JSON」** と **「個人の .env ファイル」** に加え、対象Flavorの **「エントリーポイント (-t)」** を指定する必要があります。

```bash
# 例: dev環境で実行する場合
fvm flutter run -t lib/main_dev.dart --flavor dev --dart-define-from-file=config/flavor_dev.json --dart-define-from-file=.env.dev
```

各環境の対応ファイルは以下の通りです：

| 環境 | `--flavor` | JSON 設定ファイル | `.env` ファイル |
| :--- | :--- | :--- | :--- |
| **local** | `local` | `config/flavor_local.json` | `.env.local` |
| **dev** | `dev` | `config/flavor_dev.json` | `.env.dev` |
| **stg** | `stg` | `config/flavor_stg.json` | `.env.stg` |
| **prod** | `prod` | `config/flavor_prod.json` | `.env.prod` |

---

## 🏗️ コード生成コマンド (build_runner)

モデルの定義や Riverpod プロバイダを変更した場合は、以下のコマンドを実行します。

```bash
# 一括生成（デフォルトは .env.local を使用）
fvm dart run build_runner build

# 監視モード
fvm dart run build_runner watch
```

### 特定の環境（.env）を指定して生成する

特定の環境（例: `dev`）のシークレットを反映させて `app_env.g.dart` を生成したい場合は、以下のフラグを組み合わせて実行します。

```bash
# dev環境の設定（.env.dev）を反映させて生成
fvm dart run build_runner build --define "envied_generator:envied=path=.env.dev"
```

これにより、難読化された秘密情報が対象環境のものに差し替わります。

---

## 📱 ネイティブ部分の環境による切り替え（Flavor対応）

iOS / Android のネイティブ側の設定（アプリ名やバンドルIDなど）は、`pubspec.yaml` の `flavorizr` 設定を正として、環境ごとに完全に分離されています。

### 🍎 iOS

Xcode のビルドプロセスは `ios/Flutter/*.xcconfig` ファイル群に定義されています。

1. **Firebase 設定**: ビルド時に `ios/scripts/copy_firebase_config.sh` が走り、選択された Flavor に応じた `GoogleService-Info.plist` を自動的に `Runner/` フォルダへコピーします。
2. **情報の流し込み**: `Dart-Defines.xcconfig` 経由で、`.env` ファイルや JSON 内の環境変数が `Info.plist` へ自動的に反映されます。

### 🤖 Android

Android の Flavor 設定は `android/app/flavorizr.gradle.kts` に定義されています。

1. **Firebase 設定**: Android ビルドシステムが、選択された Flavor に対応する `android/app/src/{flavor}/google-services.json` を自動的に読み込みます。
2. **リソース**: アプリ名などは `flavorizr` により生成された文字列リソース (`@string/app_name`) を参照します。
