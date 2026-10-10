# メモ機能 (Memos Feature)

## 概要

本機能は、Drift (SQLite) を活用したオフラインファーストなメモ帳機能です。\
インターネット接続がない状態でもメモの作成・編集・削除が可能で、オンライン復帰時に自動または手動でサーバーと同期する仕組みを備えています。

---

## 📁 ディレクトリ構成

```plaintext
memos/
 ├── domain/
 │    ├── memo_model.dart          # メモのデータモデル (Freezed)
 │    └── memo_sort_order.dart     # メモの並び替え（ソート）順の定義 (Enum)
 ├── data/
 │    ├── memo_table.dart          # Drift のテーブル定義
 │    ├── memos_dao.dart           # データベース操作（DAO）
 │    ├── memo_remote_service.dart # 擬似的なリモートAPI通信
 │    └── memo_repository.dart     # 同期ロジックの統合（プロバイダー定義も含む）
 ├── application/
 │    └── memo_notifier.dart       # 一覧の状態管理と操作 (Notifier)
 └── presentation/
      ├── memo_list_shimmer.dart    # メモ一覧の読み込み中骨組み（Shimmer）表示
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
- **触覚フィードバック（Haptic Feedback）**: 同期、追加、保存、削除といった主要な操作に対して、操作の重要度に応じた振動フィードバックを提供し、直感的な操作感をサポートします。

### 4. Drift + StreamNotifier によるリアクティブ UI

`MemoRepository` が提供する `Stream<List<MemoModel>>` を、`MemoNotifier` (`StreamNotifier`) で購読（`watch`）します。  
これにより、メモの追加や削除などによってローカルデータベース (Drift) のデータが書き換わると、手動で状態の再評価（`ref.invalidateSelf()`）を呼び出すことなく、変更が自動的に検知されてリアルタイムでUIへ反映されます。

### 5. 検索と並び替え機能（インクリメンタルサーチ）

既存のオフライン同期処理に影響を与えないよう、状態管理 (Riverpod) 層で安全に処理しています。

- **リアルタイム検索**: 入力されたキーワードと部分一致するメモを瞬時に絞り込み表示（インクリメンタルサーチ）。クリア（×）ボタンで即座にリセット可能。
- **多様なソート条件**: 作成日時（新旧）、更新日時（新旧）、タイトル（昇順・降順）の6つの並び替え順を、状態管理 (StreamNotifier) 層でリストをコピーしつつ適用し、安全なデータ操作を保証します。

### 6. ホーム画面ウィジェット連携（最新メモの自動同期）

メモ一覧データの変更（追加・更新・削除）は、[home_widget_sync_coordinator.dart](../lib/src/features/home_widget/application/home_widget_sync_coordinator.dart) によって自動的に検知されます。
最新の有効メモ（削除済みを除く更新日時の最も新しいメモ）およびメモ件数が、OSの共有領域（iOS App Groups / Android SharedPreferences）を介してホーム画面ウィジェットへ即座に反映されます。
ウィジェットのメモ本体タップ時はメモ一覧（`/memos`）へ直接遷移し、追加ボタン（「＋」）タップ時はディープリンク（`sampleapp://memos/create` 経由の `?action=create`）を検知して新規作成ボトムシートが自動オープンします（Core層の [app_lock_state_provider.dart](../lib/src/core/services/app_lock_state_provider.dart) の `isAppUnlockedProvider` と連携し、アプリロック解除を安全に待機します）。詳細は [ホーム画面ウィジェット連携 (home_widget.md)](home_widget.md) を参照してください。

### 7. マルチユーザー対応と完全データ分離 (Issue #314)

同一端末で複数アカウントが利用されるシナリオにおいて、ユーザー間のメモ混同やプライバシー漏洩を根本防止するため、データベースからUI層まで完全なマルチユーザー分離を実現しています。

- **テーブル定義とマイグレーション**: [memo_table.dart](../lib/src/features/memos/data/memo_table.dart) に `userId` カラム（NOT NULL）を追加し、[app_database.dart](../lib/src/app/database/app_database.dart) のスキーマバージョンを 2 から 3 へアップデート。過去の旧データはマイグレーション時に安全にクリアされます。
- **DAO & Repository のユーザー制限**: [memos_dao.dart](../lib/src/features/memos/data/memos_dao.dart) および [memo_repository.dart](../lib/src/features/memos/data/memo_repository.dart) のすべてのクエリ（一覧取得・作成・更新・削除・未同期メモ抽出）に `userId` を必須指定とし、他ユーザーのメモを一切参照・変更できない構造を担保。
- **Notifier の認証連動**: [memo_notifier.dart](../lib/src/features/memos/application/memo_notifier.dart) は [auth_service.dart](../lib/src/features/auth/application/auth_service.dart) の `currentUserIdProvider` をリアクティブに監視。未ログイン時は即座に空リスト（`[]`）を返却し、ログイン（またはアカウント切り替え）時に現在ログインしているユーザーのメモのみを即時提供します。
- **ホームウィジェット同期のユーザー連携**: [home_widget_sync_coordinator.dart](../lib/src/features/home_widget/application/home_widget_sync_coordinator.dart) においても、`getAllMemos(targetUserId)` を呼び出すことで、現在ログインしているユーザーのメモのみを抽出してウィジェットへ同期します。

---

## テスト

本機能は、データ層から UI 層まで 100% のテストカバレッジを実現しています。

- **Unit Test**:
  - `AppDatabase`: スキーマバージョン 3 へのマイグレーション検証（`app_database_test.dart`）。
  - `MemoRepository`: オフライン保存、エラー時のリトライフラグ、リモートデータとのマージロジック、および**複数ユーザー間での完全データ分離（他ユーザーのメモが混ざらないこと）**の検証。
  - `MemoNotifier`: 追加・削除・同期命令後の状態更新、未ログイン時の空配列返却、ログイン時のユーザー別メモ読み込み検証。
- **Widget Test**:
  - `MemoScreen`: 空状態の表示、ボトムシートでの入力、削除確認ダイアログ、同期ボタンの動作。
  - `MemoScreen (検索・ソート)`: 検索キーワードによる部分一致の絞り込みとクリア、ソート順変更時のメモの表示位置（並び順）の変化。
- **Golden Test**:
  - `MemoScreen`: メモ一覧画面（データあり/空）のライトモード/ダークモードでの表示確認。

---

## 関連ドキュメント

- [データ永続化の詳細（Drift / SharedPreferences）](./persistence.md)
- [ホーム画面ウィジェット連携 (home_widget.md)](home_widget.md)
