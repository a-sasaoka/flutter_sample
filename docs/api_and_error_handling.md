# API通信とエラーハンドリング

[Dio](https://pub.dev/packages/dio) と [Riverpod](https://pub.dev/packages/flutter_riverpod) を組み合わせ、外部APIからデータを取得してUIに表示する堅牢な仕組みを実装しています。
以下は `https://jsonplaceholder.typicode.com/users` を利用したユーザー一覧取得のデモアーキテクチャです。

## 📁 構成例（レイヤードアーキテクチャ）

データ構造（Domain）、取得（Data）、状態管理（Application）、表示（Presentation）を明確に分離しています。

```plaintext
lib/src/features/user/
  ├── domain/
  │   ├── user_model.dart       # Freezedで定義したユーザーモデル
  │   └── address.dart          # ネストされたモデルの分離
  ├── data/
  │   └── user_repository.dart  # API呼び出しとキャッシュ管理
  ├── application/
  │   └── user_notifier.dart    # 状態管理（ロード中・成功・エラー）
  └── presentation/
      └── user_list_screen.dart # 一覧表示画面
```

## 🌐 ネットワーク基盤とインターセプタ

このプロジェクトでは、Dioを利用した通信基盤に共通エラーハンドリング、トークン管理、ロギング処理を追加しています。

```plaintext
lib/src/core/
  ├── network/
  │   ├── api_client.dart        # Dioの共通インスタンス
  │   ├── dio_interceptor.dart   # 共通の通信ログ・エラー変換
  │   └── token_interceptor.dart # 認証トークン(Bearer)の自動リフレッシュ・付与
  └── utils/
      └── logger_provider.dart   # Talkerを用いた統合ロギング用プロバイダ
```

| 項目           | 内容                                                             |
| -------------- | ---------------------------------------------------------------- |
| 自動トークン   | `TokenInterceptor` により、全APIリクエストに安全にトークンを付与 |
| デバッグ効率   | 環境別ログ制御でノイズを削減                                     |
| エラーの一元化 | `AppException` に変換することで、UI層でのエラー分岐をシンプル化  |

---

## 🚨 共通エラーハンドリング（UI層）

アプリ全体で例外を統一的に処理するために、`ErrorHandler` クラスと `SnackBarExtension` を導入しています。

```plaintext
lib/src/core/ui/
 ├── error_handler.dart        # エラー表示の司令塔
 └── snackbar_extension.dart   # Contextの拡張メソッド（スナックバーの簡略化）
```

### 💡 Riverpodのベストプラクティス： `ref.listen` の活用

画面描画中（`build`メソッド内）に直接スナックバーを呼ぶと、エラーや無限ループの原因になります。
本プロジェクトでは、**`ref.listen`** を使用して状態変化を検知し、安全にエラーUIを表示します。

```dart
// user_list_screen.dart などの build メソッド内
ref.listen(userProvider, (previous, next) {
  // ローディングが終わり、かつエラーがある時だけ1回実行
  if (!next.isLoading && next.hasError) {
    ErrorHandler.showSnackBar(context, next.error!);
  }
});
```

### 使い分け例

- **軽い通信エラー（Snackbar）**: `ErrorHandler.showSnackBar(context, e);`
- **致命的なエラー（Dialog）**: `await ErrorHandler.showDialogError(context, e);`

---

## 🧪 通信とUIのテスト（モック化手法）

このアーキテクチャの最大のメリットは「テストのしやすさ」です。\
UIの振る舞いをテストする際、Notifierをごまかすのではなく、一番奥の **`UserRepository`（データ層）だけをモック化** することで、実際のアプリと全く同じ「通信→ロード→表示」のライフサイクルをテストできます。

```dart
// テストコードの例
final mockRepository = MockUserRepository();
when(() => mockRepository.fetchUsers()).thenAnswer((_) async => dummyUsers);

await tester.pumpWidget(
  ProviderScope(
    overrides: [
      // 💡 Repositoryだけをモックにすり替え！Notifier等は本物が動く
      userRepositoryProvider.overrideWithValue(mockRepository),
    ],
    child: const UserListScreen(),
  ),
);

// 画面の描画を待って検証
await tester.pumpAndSettle();
expect(find.text('Test User'), findsOneWidget);
```

このように、レイヤーを綺麗に分離することで、単体テストからウィジェットテストまで、カバレッジ100%を安全に達成できる構造になっています。

---
