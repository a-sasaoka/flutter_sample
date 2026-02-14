# 初期セットアップ

このドキュメントを上から順に実行すれば、新規プロジェクトを作成できる構成にしています。

---

## 前提条件

- FVM がインストール済み（[インストールガイド](https://fvm.app/documentation/getting-started/installation?utm_source=openai)）
- Flutter/Dart バージョン: **Flutter 3.35.7 / Dart 3.9.2**
- FlutterFire CLI が利用可能であること（[インストールガイド](https://firebase.google.com/docs/flutter/setup?hl=ja&platform=ios)）
- Firebase サービスの利用区分
  - 必須: Firebase Crashlytics, Firebase Analytics
  - 任意: Firebase Authentication（`USE_FIREBASE_AUTH=true` の場合に必要）

## セットアップ

- リポジトリを clone します。

```bash
git clone https://github.com/a-sasaoka/flutter_sample.git <your_app>
cd <your_app>
```

- .fvmrc で指定された Flutter バージョンをインストールし依存を取得します。

```bash
fvm install
fvm flutter pub get
```

- Firebase プロジェクトを指定して設定ファイルを生成します。

```bash
flutterfire configure --project={Firebase project ID} --out=lib/firebase_options.generated.dart
```

- プラットフォーム選択で android と iOS のチェックを入れる
- Android application id (or package name) と ios bundle id は共通の値にする
- 以下ファイルが生成されたことを確認する
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.generated.dart`

- `.env.local` を作成し編集します。

```bash
cp env.example .env.local
```

### `.env.local` で変更・確認する項目

- `FLAVOR`: `local` に変更
- `BASE_URL`: 利用する API のエンドポイントに変更
- `FIREBASE_*`: Firebase プロジェクトの実値に変更
- `APP_ID` と `FIREBASE_IOS_BUNDLE_ID`: iOS/Firebase 側の設定と一致するよう変更

> 注意1: このプロジェクトでは Firebase Crashlytics / Firebase Analytics を利用するため、`USE_FIREBASE_AUTH=false` の場合でも `FIREBASE_*` の設定は必要です。
> 注意2: ユーザー一覧のサンプルAPI動作確認する場合は `BASE_URL` に `https://jsonplaceholder.typicode.com` を指定してください。

- 転記マッピング一覧（`lib/firebase_options.generated.dart` → `.env.local`）
  - 転記し終わったら`lib/firebase_options.generated.dart`は削除しておく

| `.env.local` のキー | 転記元 |
| --- | --- |
| `FIREBASE_ANDROID_API_KEY` | `android` ブロックの `apiKey` |
| `FIREBASE_ANDROID_APP_ID` | `android` ブロックの `appId` |
| `FIREBASE_ANDROID_MSG_SENDER_ID` | `android` ブロックの `messagingSenderId` |
| `FIREBASE_ANDROID_PROJECT_ID` | `android` ブロックの `projectId` |
| `FIREBASE_ANDROID_STORAGE_BUCKET` | `android` ブロックの `storageBucket` |
| `FIREBASE_IOS_API_KEY` | `ios` ブロックの `apiKey` |
| `FIREBASE_IOS_APP_ID` | `ios` ブロックの `appId` |
| `FIREBASE_IOS_MSG_SENDER_ID` | `ios` ブロックの `messagingSenderId` |
| `FIREBASE_IOS_PROJECT_ID` | `ios` ブロックの `projectId` |
| `FIREBASE_IOS_STORAGE_BUCKET` | `ios` ブロックの `storageBucket` |
| `FIREBASE_IOS_BUNDLE_ID` | `ios` ブロックの `iosBundleId` |

### 認証モード切替（`USE_FIREBASE_AUTH`）

`.env.*` の `USE_FIREBASE_AUTH` で認証方式を切り替えできます。

- `true`: Firebase Authenticationを使用
- `false`: 自作の認証を使用

> 注意: `.env.*` のうち `AppEnv`（Envied）で参照している値を変更した場合は再生成が必要です。

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
