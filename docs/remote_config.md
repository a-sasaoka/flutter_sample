# 遠隔機能制御・バージョン通知（Firebase Remote Config）

このプロジェクトでは、Firebase Remote Config を使用して、アプリをストアで再審査・再リリースすることなく、遠隔から特定機能の有効化/無効化（フィーチャーフラグ）や、緊急告知・お知らせバナーの動的配信、およびアプリのバージョンアップを促す（または強制する）仕組みを導入しています。

---

## 📁 関連ファイル構成

```plaintext
lib/src/core/config/
 ├── feature_flags.dart            # フィーチャーフラグ・動的バナーのFreezedモデル
 ├── feature_flags_provider.dart   # フィーチャーフラグの監視・状態管理（In-App Defaults対応）
 ├── update_info.dart              # Freezedによるアップデート情報のモデル（JSONパース）
 ├── update_service.dart           # バージョン比較・判定ロジック（純粋なDartクラス）
 └── update_request_provider.dart  # Remote Configの監視・状態管理（強制アップデート用）

lib/src/features/home/presentation/widgets/
 └── announcement_banner.dart      # ホーム画面上部に表示される動的お知らせバナー
```

---

## ✨ 主な特徴と実務的な設計

ただ値を取得するだけでなく、実運用を想定した高度な仕組みが組み込まれています。

### 1. フィーチャーフラグと動的バナーの統合（`FeatureFlags`）

- **チラつきゼロの同期Notifier**: `Notifier<FeatureFlags>` として同期的に初期状態を提供するため、画面描画時にローディングスピナーが出ることなく、スムーズに初期描画が行われます。
- **In-App Defaults（アプリ内デフォルト値）**: 初回起動時やオフライン環境でも破綻しないよう、`remoteConfig.setDefaults()` を設定しています。
- **リアルタイム反映 (`onConfigUpdated`)**: Firebase Console で設定値を公開した瞬間に、アプリを再起動することなく画面の表示が即座に切り替わります。

### 2. 判定ロジックの分離とテスト容易性（強制アップデート）

バージョン比較や日付チェックなどの判定ロジックを `UpdateService` として独立させています。  
これにより、Riverpod や Firebase の環境に依存せず、純粋な単体テストで「境界値のテスト（同じバージョンの挙動など）」を確実に実施できます。

### 3. リアルタイム監視 (`onConfigUpdated`)

アプリの起動時だけでなく、**アプリを使用している最中でも** Remote Config の変更をリアルタイムで検知し、即座にアップデートダイアログを表示させることができます。

### 4. 環境（Flavor）によるフェッチ間隔の自動制御

無駄なAPI通信やFirebaseのスロットリング（制限）を防ぐため、本番環境（`prod`）では12時間のインターバルを設け、開発環境（`dev` 等）では即時（`Duration.zero`）に設定が反映されるよう、`Flavor` を使って切り替えています。

### 5. バージョン比較と時限公開の制御

現在のアプリのバージョン（`package_info_plus`）と要求バージョンを比較し、さらに「〇月〇日の12時以降になったら強制する」といった**時限公開（`enabledAt`）**の制御を正確に行っています。

---

## 🛠 Remote Config の設定方法

Firebase Console の Remote Config にて、以下のパラメータを定義します。

### 1. フィーチャーフラグ & 動的バナー用パラメータ

| パラメータキー             | 型      | デフォルト値 | 説明                                                             |
| :------------------------- | :------ | :----------- | :--------------------------------------------------------------- |
| `enable_qr_scanner`        | Boolean | `true`       | QRコードスキャナー機能の表示/非表示フラグ                        |
| `announcement_banner_text` | String  | `""`         | ホーム画面上部に表示する動的お知らせメッセージ（空文字で非表示） |

### 2. バージョンアップ通知用パラメータ (`update_info`)

パラメータキー **`update_info`** として以下の形式のJSONを定義します。

| パラメータ        | 型      | 説明                                                      |
| :---------------- | :------ | :-------------------------------------------------------- |
| `requiredVersion` | String  | 必須となる新しいアプリのバージョン（例: `2.0.0`）         |
| `canCancel`       | Boolean | `true` で「後で」ボタンを表示。`false` で強制アップデート |
| `enabledAt`       | String  | この日時以降になったら通知を有効化する（ISO8601形式）     |

#### 📝 JSON設定例

```json
{
  "requiredVersion": "2.0.0",
  "canCancel": true,
  "enabledAt": "2026-02-01T12:00:00+09:00"
}
```

---

## 🎨 UIの実装

### 1. 動的お知らせバナー（AnnouncementBanner）

- メッセージが空文字の場合は `SizedBox.shrink()` を返し、余計な余白やレイアウトシフトを発生させません。
- メッセージが設定されている場合は、Material 3 の `primaryContainer` カラーを用いた案内カードとして、ホーム画面の最上部に目立つように表示されます。

### 2. バージョンアップダイアログ（VersionUpDialog）

アップデートの通知には、`lib/src/core/widgets/version_up_dialog.dart` を使用します。

- **疎結合な設計（Pure UI）**: このダイアログは Riverpod や特定の Provider に依存せず、呼び出し側（`HomeScreen`）が状態を監視して表示のみを担当します。
- **キャンセル制御**: `canCancel` 設定に基づき、ダイアログの挙動が自動で切り替わります（`false` 時は外タップや戻るボタンを完全遮断）。

---

## 🧪 テスト・動作検証

`FirebaseRemoteConfig.instance` を直接呼び出さず、`firebaseRemoteConfigProvider` 経由でDI（依存性の注入）を行っています。

これにより、モックデータを用いたユニットテストやWidgetテストが簡単に行え、「フィーチャーフラグによるメニューの表示/非表示」「バナー文言の反映」「強制アップデート時にダイアログが消せないこと」「日時が来るまでは通知が出ないこと」などのロジックを確実にテスト保護できるアーキテクチャになっています。
