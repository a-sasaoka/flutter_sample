# 初期セットアップ

## 1️⃣ FVMで指定されているバージョンのFlutterを利用可能にする

```bash
fvm use
```

## 2️⃣ 依存パッケージのインストール

```bash
fvm flutter pub get
```

## 3️⃣ 環境設定ファイルの準備

`env.example`をコピーして、以下の4ファイルを作成します。

- `.env.local`
- `.env.dev`
- `.env.stg`
- `.env.prod`

設定内容は以下の通りです。

| 項目                      | 設定値                                                                                                                             |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| FLAVOR                    | 環境（prod, stg, dev, local のいずれか）                                                                                           |
| APP_NAME                  | アプリケーション名（とりあえず任意の値で問題ありません）                                                                           |
| APP_ID                    | Androidのパッケージ名、iOSのバンドルID（後述するFirebaseのプロジェクトにアプリを登録する際にも利用する値になります）               |
| BASE_URL                  | APIリクエストのベースとなるURL（サンプルを動かすには`https://jsonplaceholder.typicode.com`としてください）                         |
| CONNECT_TIMEOUT           | サーバーとの接続が確立されるまでの最大待機時間                                                                                     |
| RECEIVE_TIMEOUT           | レスポンスデータの受信におけるタイムアウト時間                                                                                     |
| SEND_TIMEOUT              | リクエストデータの送信におけるタイムアウト時間                                                                                     |
| USE_FIREBASE_AUTH         | 認証でFirebase Authenticationを使う場合は`true`、使わない場合は`false`                                                             |
| GOOGLE_REVERSED_CLIENT_ID | `ios/Runner/GoogleService-Info.plist`の`REVERSED_CLIENT_ID`の値（Firebase Authenticationを使わない場合は未設定でも問題ありません） |

## 4️⃣ Firebase利用準備

本プロジェクトではFirebaseの機能をデフォルトで使っているため必要な設定を行います。
Firebase自体についての説明等は本プロジェクトの趣旨とは外れてしまうのでここでは割愛します。

1. Firebaseにプロジェクトを作成し、環境設定ファイルの`APP_NAME`に記載した値と同じパッケージ名、バンドルIDでアプリを追加します。
2. `flutterfire configure --project={firebaseのプロジェクト名}`を実行します。
3. `lib/firebase_options.dart`を`lib/firebase_options_local.dart`のように環境毎のファイル名に変更してください。

現在、`android/app/google-services.json`と`ios/Runner/GoogleService-Info.plist`を環境に合わせて自動で切り替える仕組みは組み込まれていません。
そのため、`flutterfire configure --project={firebaseのプロジェクト名}`を実行する度に上記2ファイルが上書きされるので注意してください。

Firebaseは最終的には環境毎に準備されると思いますが、当初は`local`だけあれば問題ありません。
その場合、buildエラーが解消されないと思うので、その他の環境用は以下の内容でファイルを作成してください。

```dart
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
```

## 5️⃣ コード生成コマンドの実行

[こちら](docs/code_generation.md)を参考にコード生成を実行してください。

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
