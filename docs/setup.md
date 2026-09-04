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

### 💡 生体認証（Face ID / Touch ID）の OS ネイティブ設定

生体認証 (`local_auth`) を使用するため、各プラットフォームで以下のネイティブ設定が行われています。

- **iOS (`ios/Runner/Info.plist`)**:
  - `NSFaceIDUsageDescription` キーに使用理由テキスト（「アプリのロックを解除するために Face ID を使用します」）を設定しています。
- **Android (`android/app/src/main/kotlin/.../MainActivity.kt`)**:
  - 生体認証ダイアログの正常描画とコールバックのため、`FlutterActivity` ではなく `FlutterFragmentActivity` を継承するように設定されています。

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

| 項目                        | 区分 | 説明                                                                                                                                                                |
| :-------------------------- | :--- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `DEBUG_TOKEN`               | 必須 | Firebase App Check のデバッグトークン                                                                                                                               |
| `GOOGLE_REVERSED_CLIENT_ID` | 必須 | iOS の URL Scheme 設定に必要な逆クライアント ID                                                                                                                     |
| `MAPS_ANDROID_API_KEY`      | 必須 | Android Maps SDK 用 API キー（パッケージ名 + SHA-1 制限）                                                                                                           |
| `MAPS_IOS_API_KEY`          | 必須 | iOS Maps SDK 用 API キー（Bundle ID 制限）                                                                                                                          |
| `BASE_URL`                  | 任意 | API サーバー URL（チーム共通値 `config/flavor_*.json` を個人プロジェクトや端末環境に合わせて上書きする場合。※stg/prod ではローカルURLを設定しないでください）       |
| `IMAGE_BASE_URL`            | 任意 | 画像配信サーバーのベース URL（チーム共通値 `config/flavor_*.json` を個人用に上書きする場合）                                                                        |

> 🛡️ **Google Maps API キーのセキュリティ設計（ベストプラクティス）**:
>
> - **ネイティブ Maps SDK 表示キー (`MAPS_ANDROID_API_KEY` / `MAPS_IOS_API_KEY`)**: Google Maps タイル描画のためアプリ内に埋め込まれます。Google Cloud Console 側で Android（パッケージ名＋SHA-1）、iOS（Bundle ID）による厳格なアプリケーション制限を設定します。
> - **Routes API のクライアントキー廃止とサーバープロキシ構成**: Web サービス用キーをクライアントに保持させない設計を採用しています。
>   - **local 環境 (`main_local.dart`)**: API キーおよび外部通信不要の `MockRouteRepository` によるオフライン開発、またはローカル Functions エミュレータ接続が可能です。
>   - **dev / stg / prod 環境**: Firebase Cloud Functions プロキシを経由して安全に通信するため、Flutter クライアント側には Web API キーを持たせません（詳細は `docs/map.md` を参照）。

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
# 例: dev環境で実行する場合
fvm flutter run -t lib/main_dev.dart --flavor dev --dart-define-from-file=config/flavor_dev.json --dart-define-from-file=.env.dev
```

### 💡 ローカルモックサーバーの活用

本物のAPIサーバーが利用できない場合や、ローカルで自由にデータを操作してテストしたい場合は、以下の手順でモックサーバーを利用できます。詳細は [モックサーバーのドキュメント](./mock_server.md) を参照してください。

1. ターミナルで `./mock/start.sh` を実行してサーバーを起動する。
2. Flutterアプリを `local` フレーバーで起動する。

### 💡 ローカル自作APIサーバー（Firebase Functions & Firestore エミュレータ）の活用

dev環境において、ローカルPC上でAPIプログラム（Functions）およびデータストア（Firestore）のエミュレータを動かしながら、クラウド上の本物のAuthと通信してデバッグする場合は、以下の手順で実行します。詳細は [ローカル自作APIサーバーのドキュメント](./local_api_server.md) を参照してください。

1. ターミナルで `npm run --prefix functions build` を実行してAPIをビルドする。
2. `firebase emulators:start --only functions,firestore` で Functions と Firestore のエミュレータを起動する（UI: `http://localhost:4000`）。
3. Flutterアプリを `dev` フレーバーで起動する。

### 📱 ローカル HTTP 通信（Cleartext / ATS）の接続ガイド

Android エミュレータやスマホ実機から、開発用 PC のローカルサーバー（`http://10.0.2.2:5001` や `http://192.168.x.x:5001`）に接続する場合、OS のセキュリティ機能（暗号化されていない HTTP 通信の遮断）により接続エラーとなる場合があります。以下のいずれかの方法で対応してください。

#### 方法 A: HTTPS トンネルを利用する（推奨・設定変更不要）

OS の設定を変更せず、無料のトンネリングツールでローカルサーバーを一時的に HTTPS 化して接続します。

```bash
# cloudflared を使って一時的な HTTPS URL を発行する例
npx -y cloudflared tunnel --url http://localhost:5001
# 出力された https://xxx.trycloudflare.com を .env.dev の BASE_URL に設定
```

#### 方法 B: 開発環境のみ HTTP 通信を許可する

- **Android**: `android/app/src/debug/AndroidManifest.xml`（Debug 専用マニフェスト）に `android:usesCleartextTraffic="true"` が設定されています（Release ビルドでは自動で無効化されます）。
- **iOS (シミュレータ / 実機接続)**:
  - **iOS シミュレータ**: Apple 標準機能により設定不要で `localhost` への通信が許可されます。
  - **iOS 実機**: 本番用 `ios/Runner/Info.plist` のセキュリティ（HTTPS 必須）を保護するため、実機接続時は **方法 A（HTTPS トンネル）** の利用を推奨します（※ CI テスト `release_security_config_test.dart` により、本番設定ファイルに通信例外設定が含まれていないことが常に自動検証されます）。

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
chmod +x tool/hooks/pre-commit tool/setup_git_hooks.sh ios/scripts/*.sh mock/*.sh
./tool/setup_git_hooks.sh
```

---

## 🤖 E2Eテストを実行する場合

Maestro を用いた自動 E2E テストを実行する場合は、別途テストツールのインストールやセットアップが必要です。詳細は [E2Eテスト (Maestro)](./e2e_testing_maestro.md) を参照してください。
