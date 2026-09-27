# ホーム画面ウィジェット連携 (Home Widget)

## 概要

本機能は、スマートフォンのホーム画面に常駐するウィジェット（iOSの **WidgetKit** および Androidの **AppWidget**）とFlutterアプリを連携させ、アプリを開かなくても最新のメモ内容やメモ件数を確認できる機能です。
また、ウィジェットをタップした際にアプリが自動起動し、該当のメモ一覧画面（`/memos`）へ直接ジャンプするディープリンク遷移も備えています。

---

## 📁 ディレクトリ構成

ウィジェット連携機能のDart側コードは、Feature-Driven Architecture に従い `lib/src/features/home_widget` 配下に集約されています。

- **`domain/`**:
  - ウィジェット連携の定数およびID生成定義: [home_widget_constants.dart](../lib/src/features/home_widget/domain/home_widget_constants.dart)
- **`data/`**:
  - `home_widget` パッケージのネイティブAPIをラップするインターフェースと実装: [home_widget_data_source.dart](../lib/src/features/home_widget/data/home_widget_data_source.dart)
- **`application/`**:
  - ウィジェット共有ストレージへのデータ保存・多言語化・更新リクエストを担うサービス層: [home_widget_service.dart](../lib/src/features/home_widget/application/home_widget_service.dart)
  - メモ一覧データの変更を自動検知してウィジェットへ同期するコーディネーター層: [home_widget_sync_coordinator.dart](../lib/src/features/home_widget/application/home_widget_sync_coordinator.dart)

また、各OSのネイティブUIおよび連携処理は以下に配置されています。

- **iOS (Swift / SwiftUI)**:
  - ウィジェット描画・データ取得ロジック: [MemoWidget.swift](../ios/MemoWidget/MemoWidget.swift)
  - ウィジェットバンドル定義: [MemoWidgetBundle.swift](../ios/MemoWidget/MemoWidgetBundle.swift)
  - 動的App Groupsエンタイトルメント: [MemoWidget.entitlements](../ios/MemoWidget/MemoWidget.entitlements)
  - メインアプリ側エンタイトルメント: [Runner.entitlements](../ios/Runner/Runner.entitlements)
- **Android (Kotlin / RemoteViews)**:
  - ウィジェット更新レシーバー: [MemoWidgetProvider.kt](../android/app/src/main/kotlin/jp/example/sample/MemoWidgetProvider.kt)
  - ウィジェットレイアウトXML: [widget_memo.xml](../android/app/src/main/res/layout/widget_memo.xml)
  - ウィジェットメタデータ定義: [widget_memo_info.xml](../android/app/src/main/res/xml/widget_memo_info.xml)

---

## 💡 実装のポイントとアーキテクチャ

### 1. 動的 App Group ID 解決（Flavor完全非依存設計）

iOSのWidgetKitとFlutter本体の間でデータを共有するには **App Groups** を使用しますが、本プロジェクトではマルチ環境（`local`, `dev`, `stg`, `prod`）を採用しているため、ソースコード内に環境ごとの固定ID（ハードコード）を一切書かない設計を徹底しています。

- **iOSネイティブ層**:
  - `Runner.entitlements` および `MemoWidget.entitlements` に `group.$(PRODUCT_BUNDLE_IDENTIFIER)` を指定し、Xcodeビルド時にビルド変数から動的に解決します。
  - Swiftコード内では `Bundle.main.bundleIdentifier` を取得し、末尾の `.MemoWidget` を除去して `group.` 接頭辞を付与することで、常に実行中の環境に一致する App Group ID を動的に導出します。
- **Dart層**:
  - [package_info_provider.dart](../lib/src/core/utils/package_info_provider.dart) からアプリ自身のパッケージ名（`packageName`）を取得し、[home_widget_constants.dart](../lib/src/features/home_widget/domain/home_widget_constants.dart) の `appGroupIdFor` 経由で動的に `group.${packageInfo.packageName}` を生成して渡します。

### 2. メモデータ変更時の自動同期コーディネーター

メモ画面（Memos）での追加・更新・削除操作が行われた際、UIコンポーネント側にウィジェット同期の責務を持たせず、専用の [home_widget_sync_coordinator.dart](../lib/src/features/home_widget/application/home_widget_sync_coordinator.dart) が `ref.listen(memoProvider, ...)` 経由で自律的にデータ更新を検知します。

- メモ一覧から論理削除（`isDeleted`）されていない有効なメモのみを抽出。
- 最終更新日時（`updatedAt`）が最も新しいメモを先頭にソート。
- メモが0件またはすべて削除済みの場合は、多言語化対応された空状態メッセージ（「メモがありません」など）をウィジェットに反映。
- 共有ストレージへの書き込み完了後、OSに対してウィジェットの再描画をリクエスト。

### 3. 多言語対応（Localization）

ウィジェットに表示する初期状態テキストや空状態メッセージは固定の日本語ではなく、ユーザーが選択している言語設定（またはOSロケール）に合わせて英語と日本語を自動判定します。
[home_widget_service.dart](../lib/src/features/home_widget/application/home_widget_service.dart) 内で [locale_provider.dart](../lib/src/core/config/locale_provider.dart) および `AppLocalizations` を参照し、動的にローカライズされた文字列をウィジェットストレージへ格納します。

### 4. ウィジェットタップからのディープリンク画面遷移

ウィジェットをタップした際、アプリの起動状態およびアクション種別に応じてシームレスに画面遷移を処理します。
処理ロジックは [app_router.dart](../lib/src/app/router/app_router.dart) および [memo_screen.dart](../lib/src/features/memos/presentation/memo_screen.dart) に集約されています。

- **アクションの振り分け**:
  - ウィジェット全体タップ時: メモ一覧画面（`/memos`）へ直接ジャンプします。
  - 「＋新規追加」ボタンタップ時: メモ一覧画面へクエリパラメータ付きで遷移（`/memos?action=create`）し、メモ追加シートを自動展開します。
- **コールドスタート（完全終了時）とスプラッシュ待機**:
  - `homeWidgetService.getInitiallyLaunchedUri()` を取得します。スプラッシュ画面の初期化が完了するまでは遷移を安全に保留（`pendingWidgetUri`）し、スプラッシュ終了通知を受け取った段階で目的の画面へジャンプします。
- **バックグラウンド復帰時とアプリロック連携**:
  - `homeWidgetService.widgetClicked` ストリームを購読して即時遷移します。
  - パスコードロック有効時は、アプリがバックグラウンドに移行した瞬間に [app_lock_wrapper.dart](../lib/src/features/app_lock/presentation/app_lock_wrapper.dart) が即時ロック状態へと移行するため、ロック画面表示中に入力シートやキーボードが手前に誤表示されるのを防ぎ、ユーザーによる認証解除後に安全に入力シートが開くよう調和しています。

---

## 🧪 テスト検証方針

本プロジェクトの品質基準（カバレッジ100%・All Green）を満たすため、外部プラグインの呼び出しをモック化し、すべての振る舞いを単体・統合テストで検証しています。

- **サービス層テスト**: [home_widget_service_test.dart](../test/src/features/home_widget/application/home_widget_service_test.dart)
  - 初期化処理（正常系・異常系ログ記録）
  - メモ0件時の空状態データ保存
  - メモ存在時のソート・削除済み除外・最新メモ保存
  - 多言語化（日本語・英語・未対応言語フォールバック）
  - 起動URI取得およびクリックイベントストリームの委譲
- **コーディネーター層テスト**: [home_widget_sync_coordinator_test.dart](../test/src/features/home_widget/application/home_widget_sync_coordinator_test.dart)
  - アプリ起動時の自動初期化
  - メモ一覧更新検知とウィジェット更新呼び出し
- **ルーティング統合テスト**: [app_router_test.dart](../test/src/app/router/app_router_test.dart)
  - コールドスタート時およびバックグラウンド復帰時のメモ一覧遷移
  - 新規作成ディープリンクによるメモ画面遷移
- **画面表示・アクション統合テスト**: [memo_screen_test.dart](../test/src/features/memos/presentation/memo_screen_test.dart)
  - `action=create` クエリによる新規作成シート自動展開
  - パスコードロック状態に応じた入力シート表示の抑制と認証後の展開

---

## 🔗 関連ドキュメント

- [GoRouterを使ったDeepLink設定 (deeplink.md)](deeplink.md)
- [オフラインメモ機能 (memos.md)](memos.md)
- [技術スタックと開発環境 (tech_stack.md)](tech_stack.md)
- [ディレクトリ構成 (project_structure.md)](project_structure.md)
