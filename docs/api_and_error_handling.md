# API通信とエラーハンドリング

[Dio](https://pub.dev/packages/dio) と [Riverpod](https://pub.dev/packages/flutter_riverpod) を組み合わせ、外部APIからデータを取得してUIに表示する堅牢な仕組みを実装しています。\
以下は `http://localhost:3000/users`（[ローカルモックサーバー](./mock_server.md)）を利用したユーザー一覧取得のデモアーキテクチャです。

## 📁 構成例（レイヤードアーキテクチャ）

データ構造（Domain）、取得（Data）、状態管理（Application）、表示（Presentation）を明確に分離しています。

```plaintext
lib/src/features/user/
  ├── domain/
  │   ├── user_model.dart       # Freezedで定義したユーザーモデル
  │   └── address.dart          # ネストされたモデルの分離
  ├── data/
  │   └── user_repository.dart  # API呼び出しとキャッシュ管理（DI最適化済み）
  ├── application/
  │   └── user_notifier.dart    # 状態管理（ロード中・成功・エラー）
  └── presentation/
      └── user_list_screen.dart # 一覧表示画面（Cardデザイン採用）
```

## 🌐 ネットワーク基盤とインターセプタ

このプロジェクトでは、Dioを利用した通信基盤に共通エラーハンドリング、トークン管理、ロギング処理を追加しています。\
また、`ApiClient` はインターフェースとして抽象化されており、**GET, POST, PUT, PATCH, DELETE** の主要なHTTPメソッドをすべてサポートしています。

```plaintext
lib/src/core/
  ├── network/
  │   ├── api_client.dart                               # 通信の抽象インターフェースとDioによる実装
  │   ├── dio_provider.dart                             # Dioインスタンスの生成と共通設定 (baseDio, dio)
  │   ├── dio_interceptor.dart                          # 共通の通信ログ・エラー変換
  │   ├── retry_interceptor.dart                        # 電波瞬断時の自動リトライおよびべき等性キー付与
  │   └── firebase_performance_dio_interceptor.dart     # 通信パフォーマンスの自動計測 (HttpMetric)
```

| 項目                   | 内容                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| 抽象化の徹底           | `ApiClient` をインターフェース化。通信ライブラリ(Dio)への直接依存を排除                     |
| 認証の疎結合化         | `authInterceptorsProvider` を通じて、`features/auth` の `TokenInterceptor` を動的に注入     |
| 二重更新防止           | 複数の401エラーが同時に発生しても、リフレッシュAPIの呼び出しを1回に集約                     |
| 環境別設定             | `envConfigProvider` (JSON) より、環境に応じた `BASE_URL` やタイムアウトを適用               |
| パフォーマンス自動計測 | Firebase Performance により全リクエストの通信時間・データサイズを自動計測                   |
| エラーの一元化         | `AppException` に変換することで、UI層でのエラー分岐をシンプル化                             |
| 自動リトライ＆べき等性 | `RetryInterceptor` による一時障害（瞬断・502/503/504等）の自動再送と `Idempotency-Key` 付与 |

---

## 🔁 自動リトライ機構とべき等性（RetryInterceptor）

地下鉄やトンネルでの電波瞬断、またはサーバーの一時的な過負荷（502/503/504）が発生した際、ユーザーにエラーダイアログを突きつけずに透過的に通信を復旧させる仕組みとして `RetryInterceptor` を導入しています。

### 💡 主な特徴と設計

1. **一時障害のみを厳格に判定**
   - 接続タイムアウト・送受信タイムアウト・ネットワーク切断（`connectionError`）、およびサーバー一時障害（502 Bad Gateway / 503 Service Unavailable / 504 Gateway Timeout）のみをリトライ対象とします。
   - 400 Bad Request や 404 Not Found などのクライアント起因エラー、およびユーザーによる明示的な通信キャンセルはリトライしません。
2. **指数バックオフ（Exponential Backoff）**
   - リトライ待機時間を `1秒 ➔ 2秒 ➔ 4秒`（最大3回）と倍々で広げることで、復旧途中のバックエンドサーバーに負荷を集中させる「リトライ嵐（Thundering Herd問題）」を防ぎます。
3. **べき等性（Idempotency）の担保**
   - POST, PUT, PATCH などの非べき等なHTTPメソッドに対しては、初回リクエスト時に `Idempotency-Key` ヘッダーへ UUID v4 を自動付与します。
   - リトライ時も同じ `Idempotency-Key` を維持して再送するため、サーバー側で同一キーによる重複判定を行うことで、二重決済や多重投稿といった副作用を安全に防止できます。
4. **無限ループの物理遮断**
   - 再送処理には `baseDioProvider`（リトライインターセプターや認証インターセプターを含まないプレーンなDio）を使用し、リトライ処理自体が再度インターセプターを再帰呼出しするリスクを物理的に遮断しています。
   - さらに、リクエストの `extra` に保持される `_retryCountKey` により、最大試行回数（3回）を超えた場合は確実にエラーとして終了します。

---

## 🚨 共通エラーハンドリング（UI層）

アプリ全体で例外を統一的に処理するために、`ErrorHandler` クラスと `SnackBarExtension` を導入しています。

```plaintext
lib/src/core/ui/
 ├── error_handler.dart        # エラー表示の司令塔（詳細コード付与機能あり）
 └── snackbar_extension.dart   # テーマ連動型スナックバー
```

### 💡 役割と特徴

- **`ErrorHandler`**: `AppException` の種類に基づき、最適な多言語化メッセージを生成します。また、デバッグ効率向上のため、メッセージの末尾に **ステータスコード（例: (404)）を自動的に付与** します。
  - **例外メッセージの排除**: 例外発生源（RepositoryやService等）では、エラーメッセージをハードコードせず、型（`AppException` の各種 sealed クラス）のみを返します。具体的なユーザー向けメッセージは、`ErrorHandler` 内で ARB ファイルの定義に基づいて取得されます。これにより、ビジネスロジック内に特定の言語の文字列が混入することを防ぎ、保守性を高めています。
- **UXへの配慮（SnackBarの抑制）**: ユーザー一覧画面など、バックグラウンドでの更新（Pull-to-Refresh 等）に失敗した場合でも、**「画面上に古いデータ（キャッシュ）が有効に表示されている」**場合は、あえてエラーのスナックバーを表示しないように制御しています。これにより、ユーザーへの過剰な通知を減らし、スムーズな利用体験を提供します。
- **`SnackBarExtension`**: アプリ全体の `Theme` (ColorScheme) に完全に連動します。エラー時は `errorContainer`、成功時は `primaryContainer` の色を自動で使用し、視覚的な一貫性を保ちます。また、`action` 引数により「設定を開く」などのカスタムボタンを柔軟に設定できます（未指定時は自動で閉じるボタンを表示）。

---

## 🎨 ユーザー一覧 UI (UserListScreen)

ユーザー一覧画面では、Material 3 のデザインガイドラインに沿った **Card デザイン** を採用しています。

- **視覚的な整理**: `CircleAvatar` や `Icons` を活用し、各ユーザーの情報を整理して表示。
- **テーマ連動**: 配色は `ColorScheme` に追随し、ダークモード時も最適なコントラストを保ちます。
- **操作性**: `RefreshIndicator` によるスワイプ更新をサポートしており、`AlwaysScrollableScrollPhysics` により項目が少ない場合でも確実に動作します。

---

## 🧪 通信とUIのテスト（モック化手法）

このアーキテクチャの最大のメリットは「テストのしやすさ」です。

### 1. Repository層のテスト (ApiClientのモック)

`ApiClient` や `CacheManager`, `Talker` がコンストラクタ注入されているため、リポジトリ層のテストにおいてフレームワークを介さずに純粋なビジネスロジックのテストが可能です。

### 2. UI層のテスト (Repositoryのモック)

UIの振る舞いをテストする際、Notifierをごまかすのではなく、一番奥の **`UserRepository`（データ層）だけをモック化** することで、実際の通信を発生させずに Notifier や UI の状態遷移（ロード中・データ表示・エラー表示）を正確にテストできます（※実際の HTTP 通信成功・失敗ロジックは Repository 層の単体テストでカバーされます）。

具体的なテスト実装は [user_list_screen_test.dart](../test/src/features/user/presentation/user_list_screen_test.dart) を参照してください。`ProviderScope` の `overrides` で `userRepositoryProvider` のみモックに差し替え、Notifier 等は本物を動かして検証しています。

このように、レイヤーを綺麗に分離することで、単体テストからウィジェットテストまで、カバレッジ100%を安全に達成できる構造になっています。

---
