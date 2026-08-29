# 共通ユーティリティ（Core Utils）

本プロジェクトでは、アプリ全体で頻繁に利用される「ログ出力」「ネットワーク状態の監視」「アプリのライフサイクル検知」などの基盤機能を `lib/src/core/utils/` 配下に集約しています。

各機能は Riverpod の Provider を通じて提供されており、UIや他の機能（Feature層）から簡単に呼び出せるよう設計されています。

---

## 📝 1. 統合ロギング（Talker）

従来の `print` や標準の Logger に代わり、強力な統合ロギングパッケージである Talker を採用しています。

### 📁 関連ファイル

- `lib/src/core/utils/logger_provider.dart`

### 特徴と使用方法

UIやRepositoryでログを出力したい場合は、`ref.watch(loggerProvider)` または `ref.read(loggerProvider)` を使用して Talker の各ログメソッド（`debug`, `info`, `warning`, `error`, `handle`）を呼び出します。実装詳細は [logger_provider.dart](../lib/src/core/utils/logger_provider.dart) を参照してください。\
また、本プロジェクトでは **Drift（ローカルDB）のクエリログ** も Talker に統合されており、実行された SQL やその引数が自動的にログ出力されます。

### Crashlyticsとの連携ルール

`CustomTalkerObserver` を実装しており、**本番環境（prod）およびステージング環境（stg）** において、Talkerで処理されたシステムエラーが自動的に Firebase Crashlytics に「非致命的エラー（Non-fatal）」として送信されます。

- **`logger.handle(exception, stackTrace, [message])`**
  システム障害・DB破損・通信例外・パース失敗などの予期せぬエラー時に使用します。ログを出力しつつ、自動的に Crashlytics へ Non-fatal エラーとして送信されます。
- **`logger.warning('メッセージ', [exception, stackTrace])`**
  パスワード誤入力や入力バリデーションなど、ユーザーの操作起因のエラー時に使用します。ログ出力のみを行い、Crashlytics には送信されません。
- **`logger.error('メッセージ', [exception, stackTrace])`**
  Fatal エラーのログ出力や、Crashlytics への自動送信を伴わないエラーログ出力に使用します。

### 🛠 開発者用メニュー（TalkerScreen）

開発環境（`local`, `dev`, `stg`）では、ホーム画面の「開発者用ログ」ボタンから `TalkerScreen` を開くことができます。  
これにより、PCに接続していなくても、**アプリ上で直接「APIの通信履歴（リクエスト/レスポンス）」や「エラーログ」を確認**でき、テスト時のデバッグ効率が飛躍的に向上します。

---

## 🌐 2. ネットワーク状態の監視（Connectivity）

現在のデバイスがインターネットに接続されているか（Wi-Fi, モバイル通信など）をリアルタイムに判定します。

### 📁 関連ファイル

- `lib/src/core/utils/connectivity_provider.dart`

### 特徴と使用方法

「現在オンラインかどうか」を `bool` 値で返す `isOnlineProvider` を提供しています。実装詳細は [connectivity_provider.dart](../lib/src/core/utils/connectivity_provider.dart) を参照してください。  
これを監視（`watch`）することで、オフライン時にボタンを非活性（タップ不可）にしたり、API通信の前に警告を表示したりすることが可能です（利用例: [chat_screen.dart](../lib/src/features/chat/presentation/chat_screen.dart) など）。

### 💡 判定ロジックの分離

通信状態の判定ルールを `ConnectivityService` に集約しています。  
これにより、特定の接続（例：VPN）をどう扱うかといったロジックの変更やテストが、UI から独立して行えるようになっています。

---

## 🔄 3. アプリライフサイクルの監視

アプリが「バックグラウンド（非表示）」にいったん退避し、再び「フォアグラウンド（表示）」に戻ってきたタイミングなどを検知します。

### 📁 関連ファイル

- `lib/src/core/utils/app_lifecycle_provider.dart`

### 特徴と使用方法

Flutter標準の `WidgetsBindingObserver` を Riverpod でラップし、現在の状態（`AppLifecycleState`）を安全に監視できるようにしています。  
プロバイダーは `keepAlive: true` に設定されており、アプリ実行中に安定して監視を継続します。

---

## ⏰ 4. 時間の取得 (Clock)

テストの容易性と正確な時刻取得のため、現在時刻を直接取得するのではなく、プロバイダーを介して取得します。

### 📁 関連ファイル

- `lib/src/core/utils/date_time_provider.dart`

### 特徴と使用方法

`clockProvider` は **「現在の時刻を返す関数 (`DateTime Function()`)」** を提供します。実装詳細は [date_time_provider.dart](../lib/src/core/utils/date_time_provider.dart) を参照してください。  
Riverpod のキャッシュによる「時刻の固定」を防ぎ、呼び出すたびに最新の時刻（`ref.read(clockProvider)()`）を取得できます。

### テストでの利点

テストコードにおいて、`clockProvider.overrideWithValue(...)` を用いて時間を進めたり固定したりすることが容易になります（テスト実装例: [memo_repository_test.dart](../test/src/features/memos/data/memo_repository_test.dart) を参照）。

---

これらのユーティリティは、アプリの品質とユーザー体験（UX）、そして開発者体験（DX）を底上げするための強力なツールです。  
目的に応じて積極的に活用してください。

---

## 🛠 5. 開発者用ストレージ確認・編集画面

開発環境（`local`, `dev`, `stg`）では、ホーム画面の「ストレージ確認・編集」メニューから、アプリにローカル保存されているデータを直接確認・編集・削除できます。

### 📁 関連ファイル

- `lib/src/features/dev_tools/presentation/developer_storage_screen.dart`
- `lib/src/features/dev_tools/application/shared_preferences_provider.dart`
- `lib/src/features/dev_tools/application/secure_storage_provider.dart`

### 特徴と使用方法

- **対応ストレージ**: `SharedPreferencesAsync` および `FlutterSecureStorage` に保存されているデータを一覧表示します。
- **データ操作**:
  - **値の編集**: キー行をタップすると編集ダイアログが開き、値を直接編集できます。SharedPreferencesでは、データ型（String/int/double/bool）に対応した入力が可能です（`bool` の場合はスイッチUI）。
  - **個別削除**: キーの右にあるゴミ箱アイコンをタップして、個別にキーを削除できます。
  - **一括削除**: 画面右上のアイコン（ゴミ箱）から、現在開いているタブのデータを一括で全削除できます（確認ダイアログが表示されます）。
  - **新規追加**: 画面右下の「＋」ボタンから、新しいキーと値を追加できます。
  - **本番環境ガード**: 本番環境（`prod`）では、ホーム画面にメニューが表示されず、直接URL（`/dev-tools/storage`）を入力してアクセスしようとしても `NotFoundScreen` にリダイレクトされ、完全に遮断されます。

---

## ⏰ 6. 日付のローカライズ拡張（DateTimeExtension）

現在のアクティブなロケール（言語設定）に合わせて、日付と時刻を適切にフォーマットして表示するための拡張関数を提供しています。

### 📁 関連ファイル

- `lib/src/core/utils/date_time_extension.dart`
- `test/src/core/utils/date_time_extension_test.dart`

### 特徴と使用方法

`DateTime` クラスに対して、`toFormattedString([String? locale])` メソッドが拡張されています。実装詳細は [date_time_extension.dart](../lib/src/core/utils/date_time_extension.dart) を参照してください。  
このメソッドは内部で `intl` パッケージの `DateFormat` を使用し、指定されたロケール（例: `ja` で `2026/7/11 8:09`、`en` で `7/11/2026 08:09`）に応じた最適な書式に自動変換します（引数を省略、または `null` を渡した場合はシステムのデフォルトロケールが使用されます）。

UI上で日付を表示する際は、この拡張関数を利用し、引数にロケール情報（例: `l10n.localeName`）を渡すことで一貫した多言語対応の日付表示を実現できます。単体テスト実装は [date_time_extension_test.dart](../test/src/core/utils/date_time_extension_test.dart) を参照してください。

### ⏰ タイムゾーン付きフォーマット（toFormattedStringWithTimezone）

AI プロンプト等で、端末 OS から自動取得したタイムゾーン（時差オフセットおよび時差名）を含めた標準日時文字列（例: `2026-08-11 07:30 (Timezone: +09:00, JST)`）を取得するための拡張関数です。実装詳細は [date_time_extension.dart](../lib/src/core/utils/date_time_extension.dart) を参照してください。

時差指定がない文字列を AI（LLM）が UTC と誤認識して現地日付が 1 日ずれる不具合を防ぐために利用します。
