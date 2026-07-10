# 共通ユーティリティ（Core Utils）

本プロジェクトでは、アプリ全体で頻繁に利用される「ログ出力」「ネットワーク状態の監視」「アプリのライフサイクル検知」などの基盤機能を `lib/src/core/utils/` 配下に集約しています。

各機能は Riverpod の Provider を通じて提供されており、UIや他の機能（Feature層）から簡単に呼び出せるよう設計されています。

---

## 📝 1. 統合ロギング（Talker）

従来の `print` や標準の Logger に代わり、強力な統合ロギングパッケージである Talker を採用しています。

### 📁 関連ファイル

- `lib/src/core/utils/logger_provider.dart`

### 特徴と使用方法

UIやRepositoryでログを出力したい場合は、`ref.watch(loggerProvider)` または `ref.read(loggerProvider)` を使用します。\
また、本プロジェクトでは **Drift（ローカルDB）のクエリログ** も Talker に統合されており、実行された SQL やその引数が自動的にログ出力されます。

```dart
final logger = ref.read(loggerProvider);

logger.debug('デバッグ用のログです');
logger.info('API通信が成功しました');
logger.warning('リトライ可能な警告です');
```

### Crashlyticsとの連携ルール

`CustomTalkerObserver` を実装しており、**本番環境（prod）でのみ**、Talkerで処理されたエラーが自動的に Firebase Crashlytics に「非致命的エラー（Non-fatal）」として送信されます。

- **`logger.handle(exception, stackTrace)`**
  例外のログを出力しつつ、自動的に Crashlytics へ送信します。（※推奨）
- **`logger.error('メッセージ', exception, stackTrace)`**
  ログ出力のみを行い、Crashlytics には送信しません。

### 🛠 開発者用メニュー（TalkerScreen）

開発環境（`local`, `dev`, `stg`）では、ホーム画面の「開発者用ログ」ボタンから `TalkerScreen` を開くことができます。
これにより、PCに接続していなくても、**アプリ上で直接「APIの通信履歴（リクエスト/レスポンス）」や「エラーログ」を確認**でき、テスト時のデバッグ効率が飛躍的に向上します。

---

## 🌐 2. ネットワーク状態の監視（Connectivity）

現在のデバイスがインターネットに接続されているか（Wi-Fi, モバイル通信など）をリアルタイムに判定します。

### 📁 関連ファイル

- `lib/src/core/utils/connectivity_provider.dart`

### 特徴と使用方法

「現在オンラインかどうか」を `bool` 値で返す `isOnlineProvider` を提供しています。
これを監視（watch）することで、オフライン時にボタンを非活性にしたり、API通信の前にエラーを表示したりすることが可能です。

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isOnline = ref.watch(isOnlineProvider);

  return ElevatedButton(
    onPressed: isOnline ? () => submitData() : null,
    child: Text(isOnline ? '送信する' : 'オフラインです'),
  );
}
```

### 💡 判定ロジックの分離

通信状態の判定ルールを `ConnectivityService` に集約しています。これにより、特定の接続（例：VPN）をどう扱うかといったロジックの変更やテストが、UI から独立して行えるようになっています。

---

## 🔄 3. アプリライフサイクルの監視

アプリが「バックグラウンド（非表示）」にいったん退避し、再び「フォアグラウンド（表示）」に戻ってきたタイミングなどを検知します。

### 📁 関連ファイル

- `lib/src/core/utils/app_lifecycle_provider.dart`

### 特徴と使用方法

Flutter標準の `WidgetsBindingObserver` を Riverpod でラップし、現在の状態（`AppLifecycleState`）を安全に監視できるようにしています。プロバイダーは `keepAlive: true` に設定されており、アプリ実行中に安定して監視を継続します。

---

## ⏰ 4. 時間の取得 (Clock)

テストの容易性と正確な時刻取得のため、現在時刻を直接取得するのではなく、プロバイダーを介して取得します。

### 📁 関連ファイル

- `lib/src/core/utils/date_time_provider.dart`

### 特徴と使用方法

`clockProvider` は **「現在の時刻を返す関数 (`DateTime Function()`)」** を提供します。
Riverpod のキャッシュによる「時刻の固定」を防ぎ、呼び出すたびに必ず最新の時刻を取得できます。

```dart
// Repositoryなどでの利用例
final now = ref.read(clockProvider)();
```

### テストでの利点

テストコードにおいて、時間を進めたり固定したりすることが容易になります。

```dart
// テストでの上書き例
clockProvider.overrideWithValue(() => DateTime(2026, 5, 10)),
```

---

これらのユーティリティは、アプリの品質とユーザー体験（UX）、そして開発者体験（DX）を底上げするための強力なツールです。目的に応じて積極的に活用してください。

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

`DateTime` クラスに対して、`toFormattedString(String locale)` メソッドが拡張されています。このメソッドは内部で `intl` パッケージの `DateFormat` を使用し、ロケールに応じた最適な書式に自動変換します。

```dart
import 'package:flutter_sample/src/core/utils/date_time_extension.dart';

final now = DateTime.now();

// 日本語環境の場合（出力例: 2026/7/11 8:09）
final jaString = now.toFormattedString('ja');

// 英語環境の場合（出力例: 7/11/2026 08:09）
final enString = now.toFormattedString('en');
```

UI上で日付を表示する際は、常にこの拡張関数を利用し、ロケール情報を引数に渡す（例: `l10n.localeName`）ことで、一貫した多言語対応の日付表示を実現できます。
