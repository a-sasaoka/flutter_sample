# ユーザー管理機能 (User Feature)

## 概要

本機能は、[ローカルモックサーバー](./mock_server.md)（`http://localhost:3000/users`）からユーザー一覧を取得し、リスト表示するデモ機能です。\
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
 │    ├── user_notifier.dart     # 状態管理（AsyncNotifier）
 │    └── user_search_query.dart # 検索クエリと絞り込み一覧の管理 (Notifier & Provider)
 └── presentation/
      └── user_list_screen.dart   # ユーザー一覧画面（Card UI & 400msデバウンス検索バー）
```

---

## 💡 実装のポイント

### 1. キャッシュと通信のハイブリッド管理

`UserRepository` は、取得したデータを `CacheManager` を介してローカル（SharedPreferencesAsync）に保存します。

- **初回取得**: キャッシュがあれば即座に表示し、なければ API から取得します。
- **強制更新**: 「引っ張って更新（Pull-to-Refresh）」により、キャッシュを無視して最新データを取得可能です。
- **オフライン・エラー時のフォールバック**: リフレッシュ時などに API通信が失敗（オフライン等）しても、以前に取得したデータ（キャッシュ）が残っている場合は、エラー画面に切り替えずリストを表示し続けます。

### 2. コンストラクタ注入による DI

`UserRepository` は、`ApiClient`, `CacheManager`, `Talker` をコンストラクタで受け取る純粋な Dart クラスです。  
これによって、単体テストにおいてモックへの差し替えが容易になっています。

### 3. Material 3 基準の Card UI と 400ms デバウンス検索

`UserListScreen` では、情報の視認性と操作性を高めるために以下の工夫を行っています。実装詳細は [user_list_screen.dart](../lib/src/features/user/presentation/user_list_screen.dart) および [user_search_query.dart](../lib/src/features/user/application/user_search_query.dart) を参照してください。

- **400ms デバウンス検索バー**: Core層の [debouncer.dart](../lib/src/core/utils/debouncer.dart) を活用し、ユーザーの入力停止から400ms後に名前またはメールアドレスの部分一致絞り込みを実行。クリア（×）ボタンで即座にリセット可能。
- **一致キーワードのハイライト表示**: Core層の [highlighted_text.dart](../lib/src/core/widgets/highlighted_text.dart) を使用し、カード内の氏名およびメールアドレスに含まれる検索クエリと一致する文字をハイライト表示。
- **0件時の検索条件クリアボタン**: 検索結果が0件の際、専用の [EmptyStateWidget](../lib/src/core/widgets/empty_state_widget.dart) に「Clear filter」ボタンを表示し、1タップで検索窓をリセット。
- **画面外タップでのキーボード非表示**: 画面の余白タップ時に `FocusScope.of(context).unfocus()` を呼び出し、入力完了時にキーボードをスマートに閉じられます。
- **情報の整理**: 氏名、メールアドレス、住所、Webサイトをアイコンと共に Card 内に配置。
- **最終取得日時の表示**: AppBar のサブタイトルに、データが最後に API から取得された日時（YYYY/MM/DD HH:mm）を表示し、情報の鮮度をユーザーに提示します。
- **テーマ連動**: `ColorScheme` を活用し、ダークモード時も最適な配色で表示されます。
- **円形アバターの画像キャッシュ表示**: 各ユーザーカードに `AppCachedImage.circle` を適用し、Picsum等から取得した画像をメモリ最適化（RAM節約）＆ディスクキャッシュして滑らかに表示します（詳細は [パフォーマンス最適化ガイド](./performance.md) を参照）。
- **堅牢な状態表示**: ローディング中、データ空（Empty）、およびデータがない状態でのエラー時に、分かりやすい視覚的フィードバックを提供します。

---

## テスト

本機能は、モデルのシリアライズから UI の全アクションまで、**100% のテストカバレッジ**を実現しています。

- **Unit Test**:
  - `UserModel` / `Address`: JSON 変換（from/to）の正確性。
  - `UserRepository`: キャッシュ優先取得、API 取得失敗時の挙動、CRUD 操作の整合性。
  - `UserNotifier`: 状態遷移（Loading → Data / Error）の検証。
  - `UserSearchQuery`: 検索クエリの更新・クリア、および大文字小文字を区別しない部分一致（名前・メール）絞り込みの検証（`user_search_query_test.dart`）。
- **Widget Test**:
  - `UserListScreen`: 一覧描画、Empty 状態の表示、再試行ボタンの動作、Pull-to-Refresh のトリガー、大量リストのスクロール（dragUntilVisible）と画面外カードタップ検証。
  - `UserListScreen (検索機能)`: 400ms デバウンス検索、クリアボタン即時復帰、0件時の条件クリアボタンの動作、画面外タップによるキーボードフォーカス解除の検証（`user_list_screen_test.dart`）。
- **Golden Test**:
  - `UserListScreen`: ユーザー一覧画面（データあり/空/検索キーワード一致ハイライト/検索結果0件）のライトモード/ダークモードでの表示確認（`user_list_screen_golden_test.dart`）。

---

## 関連ドキュメント

- [API通信とエラーハンドリングの基盤設計](./api_and_error_handling.md)
- [キャッシュ管理（SharedPreferencesAsync）](./cache.md)
- [ローカルモックサーバー (json-server)](./mock_server.md)
