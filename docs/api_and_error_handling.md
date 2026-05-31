# API通信とエラーハンドリング

[Dio](https://pub.dev/packages/dio) と [Riverpod](https://pub.dev/packages/flutter_riverpod) を組み合わせ、外部APIからデータを取得してUIに表示する堅牢な仕組みを実装しています。\
以下は `https://jsonplaceholder.typicode.com/users` を利用したユーザー一覧取得のデモアーキテクチャです。

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
      └── user_list_screen.dart. # 一覧表示画面（Cardデザイン採用）
```

## 🌐 ネットワーク基盤とインターセプタ

このプロジェクトでは、Dioを利用した通信基盤に共通エラーハンドリング、トークン管理、ロギング処理を追加しています。\
また、`ApiClient` はインターフェースとして抽象化されており、**GET, POST, PUT, PATCH, DELETE** の主要なHTTPメソッドをすべてサポートしています。

```plaintext
lib/src/core/
  ├── network/
  │   ├── api_client.dart        # 通信の抽象インターフェースとDioによる実装
  │   ├── dio_provider.dart      # Dioインスタンスの生成と共通設定 (baseDio, dio)
  │   ├── dio_interceptor.dart   # 共通の通信ログ・エラー変換
  │   └── token_interceptor.dart # 認証トークンの自動付与・排他リフレッシュ制御
```

| 項目           | 内容                                                                          |
| -------------- | ----------------------------------------------------------------------------- |
| 抽象化の徹底   | `ApiClient` をインターフェース化。通信ライブラリ(Dio)への直接依存を排除       |
| 自動トークン   | `TokenInterceptor` により、全APIリクエストに安全にトークンを付与              |
| 二重更新防止   | 複数の401エラーが同時に発生しても、リフレッシュAPIの呼び出しを1回に集約       |
| 環境別設定     | `envConfigProvider` (JSON) より、環境に応じた `BASE_URL` やタイムアウトを適用 |
| エラーの一元化 | `AppException` に変換することで、UI層でのエラー分岐をシンプル化               |

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
- **UXへの配慮（SnackBarの抑制）**: ユーザー一覧画面など、バックグラウンドでの更新（Pull-to-Refresh 等）に失敗した場合でも、**「画面上に古いデータ（キャッシュ）が有効に表示されている」**場合は、あえてエラーのスナックバーを表示しないように制御しています。これにより、ユーザーへの過剰な通知を減らし、スムーズな利用体験を提供します。
- **`SnackBarExtension`**: アプリ全体の `Theme` (ColorScheme) に完全に連動します。エラー時は `errorContainer`、成功時は `primaryContainer` の色を自動で使用し、視覚的な一貫性を保ます。

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
check(find.byType(Card)).findsExactly(dummyUsers.length);
```

このように、レイヤーを綺麗に分離することで、単体テストからウィジェットテストまで、カバレッジ100%を安全に達成できる構造になっています。

---
