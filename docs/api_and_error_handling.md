# API通信デモ（UserList）

[Dio](https://pub.dev/packages/dio) と [Riverpod](https://pub.dev/packages/flutter_riverpod) を組み合わせ、
外部APIからデータを取得してUIに表示する仕組みを実装しています。
以下は `https://jsonplaceholder.typicode.com/users` を利用したユーザー一覧取得サンプルです。

## 📁 構成例

```plaintext
lib/src/features/user/
  ├── data/
  │   ├── user_model.dart       # Freezedで定義したユーザーモデル
  │   └── user_repository.dart  # API呼び出し
  ├── application/
  │   └── user_notifier.dart    # 状態管理（ロード中・成功・エラー）
  └── presentation/
      └── user_list_screen.dart # 一覧表示画面
```

## 主なポイント

- `Dio` の共通インスタンスを `apiClientProvider` として提供。
- `Freezed` + `JsonSerializable` による型安全なモデル変換。
- `Riverpod` アノテーション（`@riverpod`）を活用した状態管理。
- 画面では `AsyncValue` による読み込み・エラー・成功表示を制御。

---

## 通信エラーとロギング改善

このプロジェクトでは、Dioを利用した通信基盤に共通エラーハンドリングとロギング処理を追加しています。
これにより、すべてのAPI通信で統一的にエラー管理とログ出力が可能になります。

---

## 📁 追加ファイル構成

```plaintext
lib/src/core/
 ├── exceptions/
 │    └── app_exception.dart        # 共通例外クラス
 └── network/
      ├── dio_interceptor.dart      # 共通Dioインターセプタ
      └── logger_provider.dart      # 環境別ログ出力用Loggerプロバイダ
```

---

## ✅ メリット

| 項目 | 内容 |
|------|------|
| 安定性 | すべてのAPIエラーを共通で処理 |
| デバッグ効率 | 環境別ログ制御でノイズを削減 |
| 拡張性 | トークン更新やリトライ機能の追加が容易 |
| テスト容易性 | AppExceptionを使ったモックが可能 |

---

この改善により、通信処理の信頼性とデバッグ性が大幅に向上します。

---

## 共通エラーハンドリング（Snackbar & Dialog）

アプリ全体で例外を統一的に処理するために、`ErrorHandler` クラスを追加します。  
これにより、軽いエラーは **Snackbar**、致命的なエラーは **Dialog** で表示できます。

---

## 📁 ファイル構成

```plaintext
lib/src/core/ui/
 └── error_handler.dart
```

---

## 💡 使い分け例

### 軽い通信エラー（Snackbar）

```dart
ErrorHandler.showSnackBar(context, e);
```

### 致命的なエラー（Dialog）

```dart
await ErrorHandler.showDialogError(context, e);
```

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 柔軟性 | 状況に応じてSnackbarとDialogを使い分け可能 |
| 再利用性 | どの画面からも `ErrorHandler` 経由で統一的に呼び出せる |
| メンテナンス性 | メッセージロジックを一元管理 |
| UX向上 | アプリ全体で一貫したエラー体験を提供 |

これで、すべての画面で例外を安全かつ一貫してユーザーに伝えられるようになります。

---
