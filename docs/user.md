# ユーザー管理機能 (User Feature)

## 概要

本機能は、外部 API（[JSONPlaceholder](https://jsonplaceholder.typicode.com/)）からユーザー一覧を取得し、リスト表示するデモ機能です。\
API 通信、キャッシュ管理、エラーハンドリング、およびモダンなリスト UI の実装パターンを示しています。

---

## 📁 ディレクトリ構成

```plaintext
user/
 ├── domain/
 │    ├── user_model.dart        # ユーザーのデータモデル (Freezed)
 │    └── address.dart           # 住所のサブモデル
 ├── data/
 │    ├── user_repository.dart   # API通信とキャッシュの統合管理
 │    └── user_repository.g.dart # 生成されたProvider
 ├── application/
 │    └── user_notifier.dart     # 状態管理（AsyncNotifier）
 └── presentation/
      └── user_list_screen.dart   # ユーザー一覧画面（Card UI）
```

---

## 💡 実装のポイント

### 1. キャッシュと通信のハイブリッド管理

`UserRepository` は、取得したデータを `CacheManager` を介してローカル（SharedPreferencesAsync）に保存します。

- **初回取得**: キャッシュがあれば即座に表示し、なければ API から取得します。
- **強制更新**: 「引っ張って更新（Pull-to-Refresh）」により、キャッシュを無視して最新データを取得可能です。

### 2. コンストラクタ注入による DI

`UserRepository` は、`ApiClient`, `CacheManager`, `Talker` をコンストラクタで受け取る純粋な Dart クラスです。これにより、単体テストにおいてモックへの差し替えが容易になっています。

### 3. Material 3 基準の Card UI

`UserListScreen` では、情報の視認性を高めるために以下の工夫を行っています。

- **情報の整理**: 氏名、メールアドレス、住所、Webサイトをアイコンと共に Card 内に配置。
- **テーマ連動**: `ColorScheme` を活用し、ダークモード時も最適な配色で表示されます。
- **堅牢な状態表示**: ローディング中、データ空（Empty）、エラー時の各状態に対して、分かりやすい視覚的フィードバックを提供します。

---

## テスト

本機能は、モデルのシリアライズから UI の全アクションまで、**100% のテストカバレッジ**を実現しています。

- **Unit Test**:
  - `UserModel` / `Address`: JSON 変換（from/to）の正確性。
  - `UserRepository`: キャッシュ優先取得、API 取得失敗時の挙動、CRUD 操作の整合性。
  - `UserNotifier`: 状態遷移（Loading → Data / Error）の検証。
- **Widget Test**:
  - `UserListScreen`: 一覧描画、Empty 状態の表示、再試行ボタンの動作、Pull-to-Refresh のトリガー。

---

## 関連ドキュメント

- [API通信とエラーハンドリングの基盤設計](./api_and_error_handling.md)
- [キャッシュ管理（SharedPreferencesAsync）](./cache.md)
