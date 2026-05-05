# GoRouterを使ったルーティング設定

本プロジェクトでは [GoRouter](https://pub.dev/packages/go_router) を利用し、アプリ全体の画面遷移を管理しています。\
さらに [go_router_builder](https://pub.dev/packages/go_router_builder) を導入し、アノテーションによる**型安全なルーティング定義**を実現しています。

## 主な特徴

- `@TypedGoRoute` アノテーションでルートを定義し、`build_runner` により自動生成。

- 各画面は `GoRouteData` を継承し、IDE補完で安全に遷移可能。

- `const SampleRoute().go(context)` のように記述でき、パス文字列を直接書く必要がありません。

- `routerProvider` により、`Riverpod` 経由で `GoRouter` インスタンスを提供します。

---

### 📘 TypedGoRouteの使用例

ルートごとにクラスを定義して、型安全な遷移を実現します。

```dart
// lib/src/app/router/app_router.dart

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

// 画面遷移例
const HomeRoute().go(context); // "/" に遷移
```

これにより、文字列ベースのルーティング記述を避けられ、IDE補完が有効になります。
IDEでルートクラスを補完することで、タイプミスやパス指定ミスを防げます。

---

### 🧩 RiverpodアノテーションによるGoRouter管理

`GoRouter` 設定を Riverpod のアノテーション構文（`@riverpod`）で定義。\
`routerProvider` が自動生成され、明示的な `Provider<GoRouter>` 記述が不要です。

---

## 認証状態管理とルーティング制御（AuthGuard + SplashScreen）

このプロジェクトでは、`AuthStateNotifier` と `GoRouter` の `redirect` 機能を組み合わせ、\
ログイン状態に応じて画面遷移を自動制御しています。\
さらに、状態判定中のチラつきを防ぐために `SplashScreen` を導入しています。

### 🛡️ 柔軟な AuthGuard 設計（Firebase / 独自トークン両対応）

本プロジェクトの最大の強みは、認証ガード（AuthGuard）が抽象化されている点です。\
公開設定（JSON）の `USE_FIREBASE_AUTH` の値に応じて、**「Firebase認証用のガード」と「Bearerトークン認証用のガード」を自動的に切り替える**仕組みが組み込まれています。

---

### 📁 関連ファイル構成

```plaintext
lib/src/app/router/
 ├── app_router.dart                    # GoRouterのメイン定義
 ├── base_auth_guard.dart               # 認証ガードの基底クラス（リダイレクト制御の共通化）
 ├── auth_guard.dart                    # Bearerトークンベースの認証ガード
 └── firebase_auth_guard.dart           # Firebase Authentication用の認証ガード

lib/src/features/auth/application/
 ├── auth_state_notifier.dart           # トークンベースの認証状態を監視するProvider
 └── firebase_auth_state_notifier.dart  # Firebaseの認証状態を監視するProvider

lib/src/core/storage/
 └── token_storage.dart                 # トークン永続化クラス

lib/src/features/splash/presentation/
 └── splash_screen.dart                 # 起動時のローディング画面
```

---

💡\
`SplashScreen` はアプリ起動直後に一瞬だけ表示され、\
認証状態の判定（Firebaseの初期化やローカルトークンの検証）が終わるまでルーティングのチラつきを防ぎます。

---

### 🧪 動作フロー

```plaintext
アプリ起動
   ↓
SplashScreen表示（認証状態チェック）
   ↓
【認証済み】 → HomeRoute("/")へ
【未認証】   → LoginRoute("/login")へ
```

---

### ✅ メリット

| 項目     | 内容                                               |
| -------- | -------------------------------------------------- |
| 状態管理 | Riverpodでログイン状態を明示的に管理               |
| 自動遷移 | GoRouterの`redirect`で状態に応じてルート切替       |
| 拡張性   | 基底クラスにより、複数種類の認証方式を切り替え可能 |
| UX       | SplashScreenでチラつきのない自然な遷移             |

この構成により、ログイン状態を常に監視し、起動時・ログイン時・ログアウト時の画面遷移を完全に自動化・型安全化できます。

---
