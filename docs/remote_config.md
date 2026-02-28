# Firebase Remote Configを使用したバージョンアップ通知

このプロジェクトでは、Firebase Remote Configを使用してアプリがバージョンアップした際にユーザーにバージョンアップを促す仕組みを導入しています。

## 仕組み

- [UpdateRequestController](../lib/src/core/config/update_request_provider.dart)でRemote Configからのアップデート情報を監視し、アップデート情報を受け取るとホーム画面にダイアログを表示します。
- アップデート情報は以下の形式のJSONで定義し、強制アップデートやいつから有効化するかの制御が可能です。
  - requiredVersion：新しいアプリのバージョン
  - canCancel：`false`にすることで強制的アップロード
  - enabledAt：いつから有効化するか

```json
{
  "requiredVersion": "2.0.0",
  "canCancel": true,
  "enabledAt": "2026-02-01T12:00+09:00"
}
```

---
