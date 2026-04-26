# 共通ユーティリティ（Core Utils）

本プロジェクトでは、アプリ全体で頻繁に利用される「ログ出力」「ネットワーク状態の監視」「アプリのライフサイクル検知」などの基盤機能を `lib/src/core/utils/` 配下に集約しています。

各機能は Riverpod の Provider を通じて提供されており、UIや他の機能（Feature層）から簡単に呼び出せるよう設計されています。

---

## 📝 1. 統合ロギング（Talker）

従来の `print` や標準の Logger に代わり、強力な統合ロギングパッケージである Talker を採用しています。

### 📁 関連ファイル

- `lib/src/core/utils/logger_provider.dart`

### 特徴と使用方法

UIやRepositoryでログを出力したい場合は、`ref.watch(loggerProvider)` または `ref.read(loggerProvider)` を使用します。

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

---

## 🔄 3. アプリライフサイクルの監視

アプリが「バックグラウンド（非表示）」にいったん退避し、再び「フォアグラウンド（表示）」に戻ってきたタイミングなどを検知します。

### 📁 関連ファイル

- `lib/src/core/utils/app_lifecycle_provider.dart`

### 特徴と使用方法

Flutter標準の `WidgetsBindingObserver` を Riverpod でラップし、現在の状態（`AppLifecycleState`）を安全に監視できるようにしています。

**【実用例】メール認証完了の自動検知**
ユーザーが「メールアプリを開いて認証リンクを踏み、再びこのアプリに戻ってきた（`resumed`）」瞬間に、Firebaseのユーザー情報を自動更新する処理などで活用されています。

```dart
ref.listen(appLifecycleProvider, (previous, next) {
  if (next == AppLifecycleState.resumed) {
    // アプリがフォアグラウンドに戻ってきた瞬間に実行したい処理
    ref.read(authRepositoryProvider).reloadCurrentUser();
  }
});
```

---

これらのユーティリティは、アプリの品質とユーザー体験（UX）、そして開発者体験（DX）を底上げするための強力なツールです。目的に応じて積極的に活用してください。
