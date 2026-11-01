# メモ機能 (Memos Feature)

## 概要

本機能は、Drift (SQLite) を活用したオフラインファーストなメモ帳機能です。\
インターネット接続がない状態でもメモの作成・編集・削除が可能で、オンライン復帰時に自動または手動でサーバーと同期する仕組みを備えています。

---

## 📁 ディレクトリ構成

```plaintext
memos/
 ├── domain/
 │    ├── memo_category.dart       # メモのカテゴリ分類（仕事/プライベート/アイデア）(Enum)
 │    ├── memo_filter_state.dart   # 複合検索・絞り込み条件の状態モデル (Freezed)
 │    ├── memo_model.dart          # メモのデータモデル (Freezed)
 │    └── memo_sort_order.dart     # メモの並び替え（ソート）順の定義 (Enum)
 ├── data/
 │    ├── memo_table.dart          # Drift のテーブル定義（categoryカラム含む）
 │    ├── memos_dao.dart           # データベース操作（DAO: カテゴリ絞り込みクエリ含む）
 │    ├── memo_remote_service.dart # 擬似的なリモートAPI通信
 │    └── memo_repository.dart     # 同期ロジックの統合（プロバイダー定義も含む）
 ├── application/
 │    ├── memo_filter_notifier.dart # 検索・カテゴリ・未同期タグ絞り込みの状態管理 (Notifier)
 │    └── memo_notifier.dart       # 一覧の状態管理と操作 (StreamNotifier)
 └── presentation/
      ├── memo_list_shimmer.dart    # メモ一覧の読み込み中骨組み（Shimmer）表示
      └── memo_screen.dart          # メモ一覧画面（デバウンス検索・FilterChip・追加ボトムシート）
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
- **ドラッグ＆ドロップ並び替え**: カード右端のドラッグハンドルアイコンから直感的にメモの表示順を入れ替え可能です。
- **スワイプ削除 & Undo復元**: メモカードを右から左へ横スワイプするだけで安全に削除され、直後に表示される SnackBar の「元に戻す（Undo）」ボタンから即座に元の位置・元のIDのまま復元できます。
- **同期状態の可視化**: 各メモカードに「同期済み（雲チェック）」「未同期（雲オフ）」のアイコンを表示。
- **手動同期**: 通信環境が回復した際、AppBar の同期ボタンから一括送信が可能です。
- **Pull-to-Refresh**: リストを下に引っ張ることで、強制的にリモートとの同期（マージ）を実行します。
- **触覚フィードバック（Haptic Feedback）**: 同期、追加、保存、スワイプ削除、並び替えといった主要な操作に対して、操作の重要度に応じた振動フィードバックを提供し、直感的な操作感をサポートします。

### 4. Drift + StreamNotifier によるリアクティブ UI

`MemoRepository` が提供する `Stream<List<MemoModel>>` を、`MemoNotifier` (`StreamNotifier`) で購読（`watch`）します。  
これにより、メモの追加や削除などによってローカルデータベース (Drift) のデータが書き換わると、手動で状態の再評価（`ref.invalidateSelf()`）を呼び出すことなく、変更が自動的に検知されてリアルタイムでUIへ反映されます。

### 5. 検索・タグ絞り込み機能（400msデバウンス検索 & FilterChip）

オフライン同期やデータベースクエリに悪影響を与えないよう、状態管理層（`memo_filter_notifier.dart`）とUI層で責務を分離して安全に処理しています。実装詳細は [memo_filter_notifier.dart](../lib/src/features/memos/application/memo_filter_notifier.dart) および [memo_screen.dart](../lib/src/features/memos/presentation/memo_screen.dart) を参照してください。

- **400ms デバウンス検索**: 入力途中の連続再描画や無駄な検索処理を防ぐため、Core層の [debouncer.dart](../lib/src/core/utils/debouncer.dart) を活用し、最後の文字入力から 400ms 経過後に自動検索が実行されます。クリア（×）ボタン押下時はデバウンサーを即時キャンセルし、即座に全件表示へ復帰します。
- **複数タグ（FilterChip）によるカテゴリ・未同期絞り込み**: 検索窓の下部に横スクロール可能な FilterChip バー（すべて / 仕事 / プライベート / アイデア / 未同期のみ）を配置。ワンタップでカテゴリや未同期メモのみを複合的に絞り込めます。
- **一致キーワードのハイライト表示**: Core層の [highlighted_text.dart](../lib/src/core/widgets/highlighted_text.dart) を使用し、メモカードのタイトルや内容に含まれる検索クエリと一致する文字を背景色付きで視覚的に強調します。
- **0件時の検索条件クリアボタン**: 絞り込み条件（キーワードやタグ）に合致するメモが0件の場合、専用の EmptyStateWidget に「条件をクリア」アクションボタンを表示し、1タップで条件をリセットできます。
- **多様なソート条件**: 作成日時（新旧）、更新日時（新旧）、タイトル（昇順・降順）、および手動ドラッグ＆ドロップによるカスタム順の計7つの並び替え順を、状態管理 (StreamNotifier) 層でリストをコピーしつつ適用し、安全なデータ操作を保証します。ドラッグ並び替え時は自動でカスタム順へ切り替わります。
- **新規メモ作成時のカテゴリ選択**: 追加ダイアログ（ModalBottomSheet）内にもカテゴリ選択チップを搭載し、メモ登録時にカテゴリ（仕事/プライベート/アイデア/指定なし）を直感的に設定できます。

### 6. ホーム画面ウィジェット連携（最新メモの自動同期）

メモ一覧データの変更（追加・更新・削除）は、[home_widget_sync_coordinator.dart](../lib/src/features/home_widget/application/home_widget_sync_coordinator.dart) によって自動的に検知されます。
最新の有効メモ（削除済みを除く更新日時の最も新しいメモ）およびメモ件数が、OSの共有領域（iOS App Groups / Android SharedPreferences）を介してホーム画面ウィジェットへ即座に反映されます。
ウィジェットのメモ本体タップ時はメモ一覧（`/memos`）へ直接遷移し、追加ボタン（「＋」）タップ時はディープリンク（`sampleapp://memos/create` 経由の `?action=create`）を検知して新規作成ボトムシートが自動オープンします（Core層の [app_lock_state_provider.dart](../lib/src/core/services/app_lock_state_provider.dart) の `isAppUnlockedProvider` と連携し、アプリロック解除を安全に待機します）。詳細は [ホーム画面ウィジェット連携 (home_widget.md)](home_widget.md) を参照してください。

### 7. マルチユーザー対応と完全データ分離 (Issue #314 & #322)

同一端末で複数アカウントが利用されるシナリオにおいて、ユーザー間のメモ混同やプライバシー漏洩を根本防止するため、データベースからUI層まで完全なマルチユーザー分離を実現しています。

- **テーブル定義とマイグレーション**: [memo_table.dart](../lib/src/features/memos/data/memo_table.dart) に `userId` カラム（NOT NULL）を追加（v3）、さらに `category` カラム（Nullable TextColumn）を追加（v4）、そして並び順永続化用の `sortOrder` カラム（integer、デフォルト 0）を追加（v5）。[app_database.dart](../lib/src/app/database/app_database.dart) のスキーマバージョンを段階的に安全にアップデートしています。
- **DAO & Repository のユーザー制限**: [memos_dao.dart](../lib/src/features/memos/data/memos_dao.dart) および [memo_repository.dart](../lib/src/features/memos/data/memo_repository.dart) のすべてのクエリ（一覧取得・カテゴリ絞り込み・作成・更新・削除・並び順更新・未同期メモ抽出）に `userId` を必須指定とし、他ユーザーのメモを一切参照・変更できない構造を担保。
- **Notifier の認証連動**: [memo_notifier.dart](../lib/src/features/memos/application/memo_notifier.dart) は [auth_service.dart](../lib/src/features/auth/application/auth_service.dart) の `currentUserIdProvider` をリアクティブに監視。未ログイン時は即座に空リスト（`[]`）を返却し、ログイン（またはアカウント切り替え）時に現在ログインしているユーザーのメモのみを即時提供します。

### 8. AIチャット機能（Function Calling）との連携

AIチャット画面からの自然言語指示に基づき、AIエージェントがメモの新規作成（`createMemo`）や保存済みメモの検索・一覧取得（`listMemos`）を自律的に呼び出す連携機能を備えています。

- **依存性逆転（DIP）による疎結合**: メモ機能層（`features/memos`）は AIチャット機能層（`features/chat`）を一切参照していません。結合層である [app_action_dispatcher_impl.dart](../lib/src/app/actions/app_action_dispatcher_impl.dart) が Core層の抽象インターフェース [app_action_dispatcher.dart](../lib/src/core/actions/app_action_dispatcher.dart) を実装し、[memo_repository.dart](../lib/src/features/memos/data/memo_repository.dart) を呼び出すため、各機能の独立性とテスト容易性が完全に保たれています。
- **マルチユーザー保護とウィジェット連携の維持**: AI経由で作成されたメモも、現在ログインしているユーザーの `currentUserIdProvider` から取得したユーザーIDに厳格に紐付けてローカルDB（Drift）へ保存されます。作成後は既存の [home_widget_sync_coordinator.dart](../lib/src/features/home_widget/application/home_widget_sync_coordinator.dart) を通じてホーム画面ウィジェットへも即座に同期されます。

### 9. ドラッグ＆ドロップ並び替え（Optimistic UI）とスワイプ削除（Undo復元）

学習ニーズと実務での検索需要が高いリストUI操作を、堅牢なアーキテクチャと最適なユーザー体験で両立しています。実装詳細は [memo_notifier.dart](../lib/src/features/memos/application/memo_notifier.dart) および [memo_screen.dart](../lib/src/features/memos/presentation/memo_screen.dart) を参照してください。

- **Optimistic UI（即時反映）による画面チラつき防止**: Drift の Stream を直接監視している場合、ドラッグ完了から DB 更新・Stream 再発行までのラグによってアイテムが一瞬元の位置に戻るチラつきが発生します。`MemoNotifier.reorderMemos` 内でローカルの `state` を即座に並び替えて同期的に描画更新し、バックグラウンドで `memosDao.updateSortOrders` トランザクションを実行します。万一の DB 保存エラー時は元のリストへ安全にロールバックします。
- **誤操作を防ぐ明瞭な操作UX**: アイテム長押しドラッグと横スワイプ削除の誤爆を防ぐため、`buildDefaultDragHandles: false` を設定し、カード右端に配置した専用のドラッグハンドルアイコン（`ReorderableDragStartListener`）でのみ並び替えを開始できるようにしています。また、検索中やタグ絞り込み中などのフィルタ適用時はドラッグハンドルを非活性化し、意図しない順序破壊を未然に防ぎます。
- **右から左スワイプ削除 & SnackBar による Undo 復元**: `Dismissible`（`DismissDirection.endToStart`）を採用し、誤操作の少ない右から左スワイプで赤色背景＋ゴミ箱アイコンを表示して即座に論理削除（`isDeleted: true`）します。削除直後に画面下部に表示される SnackBar の「元に戻す（Undo）」ボタンをタップすると、元の `sortOrder`・元のIDのまま即座に `isDeleted: false` に更新され、元の位置へ完全に復活します。

---

## テスト

本機能は、データ層から UI 層まで 100% のテストカバレッジを実現しています。

- **Unit Test**:
  - `AppDatabase`: スキーマバージョン 3, 4, および 5 への安全なマイグレーション検証（`app_database_test.dart`）。
  - `MemosDao`: カテゴリ・未同期絞り込み、新規追加時の順序シフト（`shiftSortOrders`）、一括並び替え（`updateSortOrders`）、削除復元（`restoreMemo`）の正確性検証（`memos_dao_test.dart`）。
  - `MemoRepository`: オフライン保存、エラー時のリトライフラグ、リモートデータとのマージロジック、新規メモ先頭採番、並び替え一括保存、Undo復元、および複数ユーザー間での完全データ分離の検証（`memo_repository_test.dart`）。
  - `MemoFilterNotifier`: 検索クエリ、カテゴリ選択、未同期フラグ、カスタム順を含むソート順の更新・リセットおよびアクティブフィルタ判定の検証（`memo_filter_notifier_test.dart`）。
  - `MemoNotifier`: 追加・削除・同期命令後の状態更新、未ログイン時の空配列返却、ログイン時のユーザー別メモ読み込み、Optimistic UI 並び替えとロールバック、Undo復元の検証（`memo_notifier_test.dart`）。
- **Widget Test**:
  - `MemoScreen`: 空状態の表示、ボトムシートでの入力、同期ボタンの動作。
  - `MemoScreen (検索・タグ絞り込み・ソート)`: 400ms デバウンス検索、FilterChip によるカテゴリおよび未同期絞り込み、一致ハイライト表示、検索結果0件時の条件クリアボタンの動作、新規作成ダイアログでのカテゴリ保存の検証。
  - `MemoScreen (並び替え・スワイプ削除・Undo)`: ドラッグハンドルの活性/非活性切り替え、カスタムソートメニュー選択、右から左スワイプによる削除、および SnackBar の「元に戻す」タップによる復元検証（`memo_screen_test.dart`）。
- **Golden Test**:
  - `MemoScreen`: メモ一覧画面（データあり/空/検索キーワード一致ハイライト/カテゴリタグ絞り込み/検索結果0件）の表示確認（`memo_screen_golden_test.dart`）。

---

## 関連ドキュメント

- [データ永続化の詳細（Drift / SharedPreferences）](./persistence.md)
- [ホーム画面ウィジェット連携 (home_widget.md)](home_widget.md)
