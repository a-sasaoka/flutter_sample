# 初期セットアップ

このドキュメントを上から順に実行すれば、新規プロジェクトを作成できる構成にしています。

---

## 前提条件

- FVM がインストール済み（[インストールガイド](https://fvm.app/documentation/getting-started/installation?utm_source=openai)）
- Flutter/Dart バージョン: **Flutter 3.35.7 / Dart 3.9.2**
- Firebase は以下の設定ファイルを事前に生成しておくこと
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`
- Firebase サービスの利用区分
  - 必須: Firebase Crashlytics, Firebase Analytics
  - 任意: Firebase Authentication（`USE_FIREBASE_AUTH=true` の場合に必要）

## セットアップ

- リポジトリを clone します。

```bash
git clone https://github.com/a-sasaoka/flutter_sample.git <your_app>
cd <your_app>
```

- fvm_config.json で指定された Flutter バージョンをインストールし依存を取得します。

```bash
fvm install
fvm flutter pub get
```

- Firebase 設定ファイルを配置します。
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

- `.env.local` を作成し編集します。

```bash
cp env.example .env.local
```

### `.env.local` で変更・確認する項目

- `FLAVOR`: `local` に変更
- `BASE_URL`: 利用する API のエンドポイントに変更
- `FIREBASE_*`: Firebase プロジェクトの実値に変更
- `APP_ID` と `FIREBASE_IOS_BUNDLE_ID`: iOS/Firebase 側の設定と一致するよう変更

> 注意: このプロジェクトは起動時に `Firebase.initializeApp(...)` を実行するため、`USE_FIREBASE_AUTH=false` の場合でも `FIREBASE_*` の設定は必要です。

### 認証モード切替（`USE_FIREBASE_AUTH`）

`.env.*` の `USE_FIREBASE_AUTH` で認証方式を切り替えできます。

- `true`: Firebase Authentication（メール/パスワード認証）を使用
- `false`: APIトークン認証フローを使用

`USE_FIREBASE_AUTH` を変更した場合は、`app_env.g.dart` を更新するために Envied の再生成を実行してください。

- Envied の生成を実行します。

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
```

- 以下のコマンドで起動します（`.env.local` を使う例）:

```bash
fvm flutter run --dart-define=FLUTTER_ENV=local --dart-define-from-file=.env.local
```

### VS Code から起動する場合（`launch.json` 利用）

`.vscode/launch.json` に環境別の起動構成（`Local` / `Dev` / `Staging` / `Prod`）が用意されています。  
VS Code の「実行とデバッグ」から対象構成を選んで起動してください。

- `Local`: `--dart-define=FLUTTER_ENV=local --dart-define-from-file=.env.local`
- `Dev`: `--dart-define=FLUTTER_ENV=dev --dart-define-from-file=.env.dev`
- `Staging`: `--dart-define=FLUTTER_ENV=stg --dart-define-from-file=.env.stg`
- `Prod`: `--dart-define=FLUTTER_ENV=prod --dart-define-from-file=.env.prod`

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
