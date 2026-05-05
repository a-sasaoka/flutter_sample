# Flavor管理（マルチ環境対応）

## 概要

本プロジェクトでは、開発効率とセキュリティの両立を目指し、**4つの環境／Flavor**を完全に分離して管理しています。\
各環境はネイティブレベル（Android/iOS）およびコードレベル（Dart）で独立しており、1台の端末に複数の環境を同時にインストールすることが可能です。

### 提供されている環境

| Flavor    | 主な用途                           | アプリ名（例）   |
| :-------- | :--------------------------------- | :--------------- |
| **local** | 開発者個人のローカル開発用         | `[Local] Sample` |
| **dev**   | チーム共有の開発・検証環境         | `[Dev] Sample`   |
| **stg**   | 本番同等の検証環境（ステージング） | `[Stg] Sample`   |
| **prod**  | 本番環境                           | `Sample App`     |

---

## 🏗 アーキテクチャと設定管理

本プロジェクトでは、環境変数の管理に **「ハイブリッド構成」** を採用しています。

### 1. 公開設定 (`config/flavor_*.json`)

- **役割**: チーム内で共有すべき、環境ごとの挙動設定。
- **管理方法**: Git 管理対象。
- **主な項目**: `BASE_URL`, `AI_MODEL`, タイムアウト値、機能フラグ等。
- **取得手段**: `ref.watch(envConfigProvider)`

### 2. 秘匿情報・個人設定 (`.env.*`)

- **役割**: 各自の Firebase 環境に依存する ID や、API キーなどの秘密情報。
- **管理方法**: **Git 管理外 (`.gitignore`)**。`env.example` をコピーして各自作成。
- **主な項目**: `DEBUG_TOKEN`, `GOOGLE_REVERSED_CLIENT_ID`
- **取得手段**: `AppEnv` (Envied による難読化)

---

## 🧩 コードレベルの役割分担

| クラス / プロバイダー     | 責務                                                                   |
| :------------------------ | :--------------------------------------------------------------------- |
| **エントリーポイント**    | `lib/main_*.dart`。各Flavorに対応し、`mainCommon(Flavor.xxx)` を実行。 |
| **`Flavor` (enum)**       | 「どの環境か」を識別する。`mainCommon` の引数として渡される。          |
| **`envConfigProvider`**   | JSON ファイルから読み込んだ「公開設定」をアプリ全体に提供する。        |
| **`AppEnv` (Envied)**     | `.env` ファイルから読み込んだ「秘密情報」を安全に提供する。            |
| **`packageInfoProvider`** | アプリ名や Application ID を OS から直接取得する（二重管理を防止）。   |

---

## 📱 ネイティブ層の挙動

### Firebase 設定の自動切り替え

各環境に応じた Firebase 設定ファイルが、ビルド時に自動で選択されます。

- **Android**: `android/app/src/{flavor}/google-services.json` を配置。
- **iOS**: ビルド時にスクリプトが `ios/Runner/Firebase/{flavor}/GoogleService-Info.plist` をコピー。

### アイコンの識別

ホーム画面で環境を一目で判別できるよう、アイコンの背景色が変更されています。
（`flutter_launcher_icons` により `pubspec.yaml` の設定に基づき自動生成）

---

## 🚀 実行方法

### VS Code から実行

`.vscode/launch.json` に全環境の設定が登録されています。「実行とデバッグ」タブから対象の環境を選択して起動してください。

### コマンドラインから実行

`--flavor` と `--dart-define-from-file` に加え、対象Flavorのエントリーポイントを `-t` で指定して実行します。

```bash
# dev環境の実行例
fvm flutter run -t lib/main_dev.dart --flavor dev --dart-define-from-file=config/flavor_dev.json --dart-define-from-file=.env.dev
```

---

## 🛠 設定の追加・変更方法

1. **アプリ名や ID を変えたい**: `pubspec.yaml` の `flavorizr:` セクションを修正し、`fvm flutter pub run flutter_flavorizr` を実行してください。
2. **新しい公開設定（URL等）を増やしたい**: `config/*.json` に項目を追加し、`env_config.dart` の `EnvConfigState` を更新してください。
3. **新しい秘密情報（APIキー等）を増やしたい**: `.env.*` に項目を追加し、`app_env.dart` の `AppEnv` クラスを更新してください。
