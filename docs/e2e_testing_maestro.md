# 📱 E2Eテスト (Maestro)

このプロジェクトでは、アプリ全体の画面遷移やユーザーの操作フローをロボットのように自動でテストするために、**Maestro** を使用したE2E（エンドツーエンド）テストを導入しています。

---

## 📌 E2Eテストとは？

アプリを実際にシミュレータ上で起動し、「ボタンをタップする」「文字を入力する」といった人間の操作を自動で再現して、アプリが最初から最後まで正しく動くかを確認するテストです。

---

## 🧭 テスト実行の環境とモック

テストを安全かつ高速に実行するため、以下の設定を採用しています。

1. **iOSシミュレータのみが対象**
   - macOS のシミュレータ上で自動テストを実行します。
2. **local Flavor の使用**
   - 開発環境（`local`）を使用し、安全にローカルで検証します。
3. **E2E専用の起動設定 (`lib/main_e2e.dart`)**
   - **認証と通信のモック**: Firebase Auth を無効化し、ネットワーク状態をオフラインに固定（通信を遮断）して不要なAPI接続が発生しないよう Riverpod プロバイダを上書きしています。
   - **アプリアプデ判定のバイパス**: テスト中に不要な「最新版への更新」ダイアログが出ないようにしています。
   - **暗号化ストレージのモック (`FakeSecureStorage`)**: iOSシミュレータのキーチェーン制限やプロセス再起動に左右されずトークン・パスコードを保持できるよう、一時ファイル (`Directory.systemTemp`) を使って安全かつ確実に状態を管理・復元するフェイクストレージを注入しています。
   - **生体認証のモック固定**: E2Eテスト中、OSの生体認証（Face ID / Touch ID）ダイアログによってテストが中断・ブレるのを防ぐため、`localAuthenticationProvider` を「利用不可 (`canCheckBiometrics = false`)」として固定しています。

---

## 🛠️ テストの実行手順

### 1. iOSシミュレータの起動

シミュレータが起動していない場合は、macOSのターミナルから起動します。

```bash
open -a Simulator
```

### 2. テスト専用アプリをビルドして起動

FVM を使用して、E2Eテスト専用のエントリポイントでアプリをシミュレータ上で実行します。

```bash
fvm flutter run --flavor local -t lib/main_e2e.dart --dart-define-from-file config/flavor_local.json --dart-define-from-file .env.local -d <iOS_SIMULATOR_ID>
```

※起動が完了し、デバッグツール（VM Service）のURLが表示されるまで待機します。

### 3. Maestroテストの実行

別のターミナルを開き、定義したテストフロー（YAMLファイル）を実行します。

```bash
# 基本ログインフローの検証
~/.maestro/bin/maestro test maestro/app_launch_and_login.yaml

# アプリロック機能（設定・アプリ復帰・パスコード解錠）の検証
~/.maestro/bin/maestro test maestro/app_lock_flow.yaml
```

※テストが走り、全てのステップが「COMPLETED」になれば成功です。

---

## 📂 テストシナリオの構成

テストフローは `maestro/` ディレクトリ配下で管理されています。

- **[maestro/app_launch_and_login.yaml](../maestro/app_launch_and_login.yaml)**: 起動 $\rightarrow$ オンボーディングスキップ $\rightarrow$ ログイン $\rightarrow$ 4桁パスコード初期登録 (`1234` + `1234`) $\rightarrow$ ホーム表示までの基本最短フローを検証。
- **[maestro/app_lock_flow.yaml](../maestro/app_lock_flow.yaml)**: ログイン＆パスコード登録後、生体認証プロンプト閉じに伴う誤ロック防止ロジック (`_shouldSkipNextLock`) の挙動を踏まえ、バックグラウンド復帰動作 (`pressKey: Home` $\rightarrow$ `launchApp`) により自動表示されるロック画面 (`PasscodeLockScreen`) を 4桁パスコード (`1234`) で解除するリアルなアプリロック解錠テスト。
- iOSのアクセシビリティ仕様（ラベルの改行結合）に対応するため、入力フィールドのタップなどには正規表現（regex）を用いて確実に要素を検出する工夫をしています。
