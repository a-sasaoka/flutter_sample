# バージョンアップ通知（Firebase Remote Config）

このプロジェクトでは、Firebase Remote Config を使用して、アプリがバージョンアップした際にユーザーへアップデートを促す（または強制する）仕組みを導入しています。

---

## 📁 関連ファイル構成

```plaintext
lib/src/core/config/
 ├── update_info.dart              # Freezedによるアップデート情報のモデル（JSONパース）
 └── update_request_provider.dart  # Remote Configの監視・バージョン比較ロジック
```

---

## ✨ 主な特徴と実務的な設計

ただ値を取得するだけでなく、実運用を想定した高度な仕組みが組み込まれています。

### 1. リアルタイム監視 (`onConfigUpdated`)

アプリの起動時だけでなく、**アプリを使用している最中でも** Remote Config の変更をリアルタイムで検知（`onConfigUpdated.listen`）し、即座にアップデートダイアログを表示させることができます。

### 2. 環境（Flavor）によるフェッチ間隔の自動制御

無駄なAPI通信やFirebaseのスロットリング（制限）を防ぐため、本番環境（`prod`）では12時間のインターバルを設け、開発環境（`dev` 等）では即時（`Duration.zero`）に設定が反映されるよう、`Flavor` を使って切り替えています。

### 3. バージョン比較と時限公開の制御

現在のアプリのバージョン（`package_info_plus`）と要求バージョンを比較し、さらに「〇月〇日の12時以降になったら強制する」といった**時限公開（`enabledAt`）**の制御を正確に行っています。

---

## 🛠 Remote Config の設定方法

Firebase Console の Remote Config にて、パラメータキー **`update_info`** として以下の形式のJSONを定義します。

| パラメータ        | 型      | 説明                                                      |
| ----------------- | ------- | --------------------------------------------------------- |
| `requiredVersion` | String  | 必須となる新しいアプリのバージョン（例: `2.0.0`）         |
| `canCancel`       | Boolean | `true` で「後で」ボタンを表示。`false` で強制アップデート |
| `enabledAt`       | String  | この日時以降になったら通知を有効化する（ISO8601形式）     |

### 📝 JSON設定例

```json
{
  "requiredVersion": "2.0.0",
  "canCancel": true,
  "enabledAt": "2026-02-01T12:00:00+09:00"
}
```

---

## 🧪 テスト・動作検証

`FirebaseRemoteConfig.instance` を直接呼び出さず、`firebaseRemoteConfigProvider` 経由でDI（依存性の注入）を行っています。

これにより、モックデータを用いたユニットテストやWidgetテストが簡単に行え、「強制アップデート時にダイアログが消せないこと」や「日時が来るまでは通知が出ないこと」などのロジックを確実にテスト保護できるアーキテクチャになっています。

---
