# コード生成と環境切り替え

本プロジェクトでは、ボイラープレート（定型コード）の削減と型安全性の向上のため、強力なコード生成ツール群を活用しています。

## 📦 コード生成の対象パッケージ

以下のパッケージを利用してコードを自動生成（`*.g.dart`, `*.freezed.dart`）しています。
対象となるファイルを変更した場合や、新たにプロジェクトをクローンした直後は、必ずコード生成コマンドを実行してください。

- **Riverpod Generator**: 状態管理のプロバイダ生成
- **Freezed / json_serializable**: イミュータブルなデータモデルとJSONパース処理
- **GoRouter Builder**: `@TypedGoRoute` による型安全なルーティング定義
- **Envied**: `.env` ファイルからの環境変数クラス（難読化付き）の生成

---

## ⚙️ 環境の切り替えとコード生成コマンド

コード生成時に使用する `.env` ファイルを環境（Flavor）ごとに切り替えることができます。
以下のコマンドを使用して、対象の環境設定に合わせて生成してください。

> ⚠️ **注意**: `.env` ファイル内の値（APIキーやURLなど）を書き換えただけではアプリには反映されません。変更した場合は、**必ず対象環境の `build_runner` コマンドを再実行**して `app_env.g.dart` を更新してください。

（※ `envied_generator:envied` の指定がない場合は、デフォルトで Local 環境用 `.env.local` 等が参照されます。）

### Local環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
```

### Dev環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.dev"
```

### Staging環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.stg"
```

### Production環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.prod"
```

---

## 👀 監視モード（開発中推奨）

`build` の代わりに `watch` を使用すると、ファイルの変更を監視し、保存するたびに自動で差分のみコード生成が行われます。
UI開発やモデル定義を連続して行う場合はこちらが便利です。

```bash
fvm dart run build_runner watch --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
```

---

## 📱 ネイティブ部分の環境による切り替え（Flavor対応）

Flutter側だけでなく、iOS / Android のネイティブ側の設定（アプリ名やバンドルIDなど）も、単一の `.env` ファイルを正として環境ごとに切り替える仕組みを構築しています。

### 🍎 iOS

Xcodeのビルドプロセスに介入し、コンパイル前に環境変数を注入します。

1. `ios/scripts/extract_dart_defines.sh` を Build Phases (PreActions) として実行し、指定された `.env` ファイルから値を取得します。
2. 取得した値は `ios/Runner/Info.plist` や `ios/Runner.xcodeproj/project.pbxproj` 内で `$(APP_NAME)` や `$(APP_ID)` のように参照され、アプリアイコン名やFirebase設定などに利用されます。

### 🤖 Android

Gradleのビルドスクリプトで環境変数を読み込みます。
_defines.sh` を Build Phases (PreActions) として実行し、指定された `.env` ファイルから値を取得します。
2. 取得した値は `ios/Runner/Info.plist` や `ios/Runner.xcodeproj/project.pbxproj` 内で `$(APP_NAME)` や `$(APP_ID)` のように参照され、アプリアイコン名やFirebase設定などに利用されます。

### 🤖 Android

Gradleのビルドスクリプトで環境変数を読み込みます。

1. `android/app/build.gradle.kts` 内で `.env` ファイルをパースし、`dartDefines["APP_NAME"]` のようにマップとして保持します。
2. `resValue("string", "app_name", dartDefines["APP_NAME"] ?: "Flutter Sample")` のようにリソースを動的生成することで、`android/app/src/main/AndroidManifest.xml` 内にて `@string/app_name` のように安全に参照できます。

---
