# メモ機能 (Memos Feature)

## 概要

本機能は、Drift (SQLite) を活用したオフラインファーストなメモ帳機能です。\
インターネット接続がない状態でもメモの作成・編集・削除が可能で、オンライン復帰時に自動または手動でサーバーと同期する仕組みを備えています。

---

## 📁 ディレクトリ構成

```plaintext
memos/
 ├── domain/
 │    └── memo_model.dart          # メモのデータモデル (Freezed)
 ├── data/
 │    ├── memo_table.dart          # Drift のテーブル定義
 │    ├── memos_dao.dart           # データベース操作（DAO）
 │    ├── memo_remote_service.dart # 擬似的なリモートAPI通信
 │    ├── memo_repository.dart     # ローカルとリモートの同期ロジックを統合
 │    └── memo_provider.dart       # リポジトリのDI定義
 ├── application/
 │    └── memo_notifier.dart       # 一覧の状態管理と操作 (Notifier)
 └── presentation/
      └── memo_screen.dart          # メモ一覧画面と追加ボトムシート
```

---

## 💡 実装のポイント

### 1. オフラインファーストな同期設計

`MemoRepository` がデータの「番人」となり、以下のロジックで整合性を保ちます。

- **保存**: 常にローカル DB へ即座に書き込み、オンラインならバックグラウンドでリモートへ送信。成否を `isSynced` フラグで管理。
- **取得**: リモートから最新データを取得し、`updatedAt`（最終更新日時）を比較して、より新しいデータをローカルへマージ。
- **論理削除**: データを物理的に消さず `isDeleted` フラグで管理することで、マルチデバイス間の削除同期を確実に行います。

### 2. コンストラクタ注入による DI の徹底

`MemoRepository` は Riverpod の `Ref` に依存せず、必要な機能（DB, API, Logger, Clock, Connectivity）をすべてコンストラクタで受け取ります。\
これにより、特定のライブラリや状態管理フレームワークに縛られない、純粋なビジネスロジックとしてのテストが可能です。

### 3. 洗練された UI/UX

- **追加フロー**: FAB から `ModalBottomSheet` を開き、一覧を隠さずスムーズに入力できます。
- **同期状態の可視化**: 各メモカードに「同期済み（雲チェック）」「未同期（雲オフ）」のアイコンを表示。
- **手動同期**: 通信環境が回復した際、AppBar の同期ボタンから一括送信が可能です。
- **Pull-to-Refresh**: リストを下に引っ張ることで、強制的にリモートとの同期（マージ）を実行します。

---

## テスト

本機能は、データ層から UI 層まで 100% のテストカバレッジを実現しています。

- **Unit Test**:
  - `MemoRepository`: オフライン保存、エラー時のリトライフラグ、リモートデータとのマージロジック。
  - `MemoNotifier`: 追加・削除・同期命令後の状態更新（invalidateSelf）。
- **Widget Test**:
  - `MemoScreen`: 空状態の表示、ボトムシートでの入力、削除確認ダイアログ、同期ボタンの動作。

---

## 関連ドキュメント

- [データ永続化の詳細（Drift / SharedPreferences）](./persistence.md)
