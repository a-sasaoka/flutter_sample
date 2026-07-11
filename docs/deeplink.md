# GoRouterを使ったDeepLink（ディープリンク）設定

本プロジェクトでは、アプリ外（Webサイトや他のアプリ、メールなど）からの遷移をフックして特定の画面を直接開くための **DeepLink（ディープリンク）** を実装しています。
GoRouter とプラットフォームのネイティブ連携により、安全でシームレスな画面遷移を提供します。

## 主な特徴

- **ハイブリッド方式**: 簡易的な `Custom URL Scheme` と、ドメイン検証を行うセキュアな `App Links / Universal Links` の両方を導入。
- **環境（Flavor）ごとの分離**: `dev`, `stg`, `prod` などのビルド環境ごとに異なるスキーム名およびドメイン名を設定し、開発中の誤遷移を防止。
- **型安全な遷移ハンドリング**: `go_router_builder` で自動生成されたルート定義を利用して遷移をハンドリング。
- **認証状態と連動した自動リダイレクト**: 未ログイン時にディープリンク経由で認証必須画面を開こうとした場合、ログイン画面に飛ばし、ログイン完了後に自動で本来の目的地へ遷移（リダイレクトバック）。

---

## 環境ごとの定義

ディープリンクで使用する各環境（Flavor）のカスタムスキームおよび連携ドメインは以下の通り定義されています。

| 環境 (Flavor) | パッケージID (Android) / バンドルID (iOS) | Custom URL Scheme  | 連携ドメイン (App Links / Universal Links)                      |
| :------------ | :---------------------------------------- | :----------------- | :-------------------------------------------------------------- |
| **local**     | `jp.example.sample.local`                 | `flsamplelocal://` | `.env.local` の `APP_LINK_DOMAIN` (例: `your-local-id.web.app`) |
| **dev**       | `jp.example.sample.dev`                   | `flsampledev://`   | `.env.dev` の `APP_LINK_DOMAIN` (例: `your-dev-id.web.app`)     |
| **stg**       | `jp.example.sample.stg`                   | `flsamplestg://`   | `.env.stg` の `APP_LINK_DOMAIN` (例: `your-stg-id.web.app`)     |
| **prod**      | `jp.example.sample`                       | `flsample://`      | `.env.prod` の `APP_LINK_DOMAIN` (例: `example.com`)            |

※iOSの Universal Links については、実機テスト時に Apple Developer アカウント（有料）および Team ID が必要となるため、開発フェーズ初期では Custom URL Scheme による起動検証を中心とし、本番ビルドに向けて Universal Links を有効化します。

---

## 認証ガードとの統合とリダイレクトバック仕様

未ログインの状態で認証が必要な画面（例: `/memos`）へのディープリンクを開いた場合、以下の動作フローで元の目的地へ復帰させます。

### 🔄 ログイン後リダイレクトの動作フロー

```plaintext
アプリ外からディープリンク（https://your-firebase-project-id.web.app/memos）をタップ
   ↓
OSがアプリを検知し起動 ＆ 初期パス `/memos` を GoRouter に通知
   ↓
GoRouter のリダイレクト判定（authGuard / firebaseAuthGuard）が実行
   ↓
【未認証状態】
   ↓
現在地 `/memos` をクエリパラメータ `from` にエンコードしてログイン画面にリダイレクト
遷移先: `/login?from=%2Fmemos`
   ↓
ユーザーがログインを完了
   ↓
ログイン画面のコントローラが `from` パラメータの存在を検知
   ├─【fromあり】 ──→ デコードしたパス（`/memos`）へ遷移
   └─【fromなし】 ──→ デフォルトのホーム画面（`/`）へ遷移
```

---

## ネイティブ（OS）側の設定構成

### 📱 Androidの設定

各 Flavor ごとに Custom URL Scheme と App Links を処理するための `<intent-filter>` を `AndroidManifest.xml` に設定し、`manifestPlaceholders` から動的に値を割り当てます。

- **設定ファイル**: `android/app/flavorizr.gradle.kts`
  各Flavorの `manifestPlaceholders` に `customUrlScheme` を定義します。`appLinkDomain` については開発者個人でドメインが異なるため、`.env.{flavor}` から `APP_LINK_DOMAIN` の値をビルド時に自動で取得する仕組みを採用しています。
- **設定ファイル**: `android/app/src/main/AndroidManifest.xml`
  `<activity>` 要素内にインテントフィルタを追加します。

### 🍎 iOSの設定

iOSでは、無料環境で動作テストができる「Custom URL Scheme」の設定は**すでに完了**していますが、有料アカウントが必要な「Universal Links」の設定は**今後対応が必要**になります。

#### ✅ 実装済みの設定（Custom URL Scheme 用）

ローカル環境ですぐに動作確認ができるよう、以下のネイティブ構成は設定済みです。

- **ビルド変数定義** (`ios/Flutter/*.xcconfig`):  
  環境ごとに `CUSTOM_URL_SCHEME=flsamplelocal` などのスキーム名を定義済みです。
- **`Info.plist` での設定** (`ios/Runner/Info.plist`):
  - `CFBundleURLTypes` に `$(CUSTOM_URL_SCHEME)` を登録し、アプリ起動を有効化済みです。
  - iOSからFlutterへディープリンクのパスを引き渡すための鍵である `<key>FlutterDeepLinkingEnabled</key><true/>` を設定済みです。

#### ⏳ 今後対応が必要な設定（Universal Links 用）

通常のURLから起動する Universal Links を有効にするためには、Apple Developerの有料アカウント取得後に以下の設定を手動で行う必要があります。
（※有料アカウントとの紐づけがない状態でこれらをアプリに設定すると、署名エラーでビルドが失敗するため、現状は未設定です）

1. **Apple Developer アカウントの準備**:  
   有料の Apple Developer Program に登録し、マイアカウントから **`Team ID`** を取得します。
2. **Xcode上での Associated Domains の有効化**:  
   Xcodeでプロジェクトを開き、`Runner` ターゲットの `Signing & Capabilities` タブから **`+ Capability`** > **`Associated Domains`** を追加します。
3. **ドメインの登録**:  
   追加された項目に以下を登録します（`Runner.entitlements` ファイルが自動生成されます）。
   - 登録内容: `applinks:$(APP_LINK_DOMAIN)`  
     ※ `$(APP_LINK_DOMAIN)` はビルド時に `.env.*` の値から動的に解決されるため、Gitに個人ドメインを残さず安全に構築できます。

---

## アソシエーションファイルの配置

App Links（Android）および Universal Links（iOS）のドメイン検証を行うため、Firebase Hosting の公開ディレクトリ配下に以下の設定ファイルを配置します。

### iOS用: `/.well-known/apple-app-site-association`

※拡張子はなしで保存します

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<YOUR_APPLE_TEAM_ID>.<YOUR_APP_BUNDLE_IDENTIFIER>",
        "paths": ["/memos", "/chat", "/settings", "/chart-input", "/users"]
      }
    ]
  }
}
```

- **`appID`**: Apple Developer の Team ID と、各環境の Bundle ID を組み合わせたものです（例: `A1B2C3D4E5.jp.example.sample.local`）。
- **`paths`**: アプリで直接開くことを許可するパスのリストです。

### Android用: `/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "<YOUR_APP_PACKAGE_NAME>",
      "sha256_cert_fingerprints": ["<YOUR_SHA256_CERT_FINGERPRINT>"]
    }
  }
]
```

- **`package_name`**: 各環境のアプリケーションIDを指定します（例: `jp.example.sample.local` や `jp.example.sample.dev`）。
- **`sha256_cert_fingerprints`**: アプリの署名に使用したキーストアの SHA-256 フィンガープリントを指定します（開発時はPCのデバッグ用鍵、本番は公開用の署名鍵など）。

### ⚠️ Git 管理と共有に関する重要事項

- 個人で開発・デバッグを行うための実ファイル（`public/.well-known/assetlinks.json` や `public/.well-known/apple-app-site-association`）は、ローカル用の鍵情報や Firebase Hosting の設定に依存するため、**Git 管理対象外（`.gitignore` で無視）**としています。
- 代わりに、共通のひな形として `apple-app-site-association.example` および `assetlinks.json.example` を Git にコミットし共有しています。
- 新しく環境構築を行う場合は、これらのテンプレートファイルをコピーして実ファイルを作成し、各自の環境（Team ID や SHA-256 フィンガープリント）に合わせて編集してください。

---

## 🧪 動作確認手順

Custom URL Scheme を使用してローカル環境で動作検証を行う場合は、URIパーサーがホスト名とパスを正しく解釈できるように、`/` の数やダミーホスト（`localhost`）に注意して実行する必要があります。

### 1. アプリの起動

VSCodeのデバッグランチャーから **`flutter_sample (local)`** を選択して起動するか、ターミナルで環境変数などを指定した以下のコマンドを実行します。

```bash
fvm flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config/flavor_local.json --dart-define-from-file=.env.local
```

### 2. 検証コマンドの実行

`flsamplelocal://memos` と実行すると `memos` がホスト名として認識され、パスが空（`/`）になり遷移しません。
そのため、以下のいずれかの形式でコマンドを実行します。

#### 🍎 iOS (シミュレータ)

```bash
# スラッシュを3つにする形式
xcrun simctl openurl booted "flsamplelocal:///memos"

# localhost をホスト名として挟む形式
xcrun simctl openurl booted "flsamplelocal://localhost/memos"
```

#### 🤖 Android (エミュレータ)

```bash
# スラッシュを3つにする形式
adb shell am start -W -a android.intent.action.VIEW -d "flsamplelocal:///memos" jp.example.sample.local

# localhost をホスト名として挟む形式
adb shell am start -W -a android.intent.action.VIEW -d "flsamplelocal://localhost/memos" jp.example.sample.local
```

### 3. Android App Links の検証（Web連携）

アソシエーションファイルを配置した Firebase Hosting から App Links を起動するテストを行います。

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://your-firebase-project-id.web.app/memos" jp.example.sample.local
```
