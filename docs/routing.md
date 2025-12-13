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
// lib/src/core/router/app_router.dart

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

このプロジェクトでは、`AuthStateNotifier` と `GoRouter` の `redirect` 機能を組み合わせ、  
ログイン状態に応じて画面遷移を自動制御しています。  
さらに、状態判定中のチラつきを防ぐために `SplashScreen` を導入しています。

---

### 📁 追加ファイル構成

```plaintext
lib/src/core/auth/
 ├── auth_state_notifier.dart   # ログイン状態を監視するProvider
 ├── auth_guard.dart            # GoRouter用ガード関数
 └── token_storage.dart         # トークン保存クラス（既存）

lib/src/features/splash/
 └── presentation/
     └── splash_screen.dart     # 起動時のローディング画面
```

---

💡  
`SplashScreen` はアプリ起動直後に一瞬だけ表示され、  
認証状態の判定が終わるまでルーティングのチラつきを防ぎます。

---

### 🧪 動作フロー

```plaintext
アプリ起動
   ↓
SplashScreen表示（認証状態チェック）
   ↓
トークン保持あり → HomeRoute("/")へ
トークンなし → LoginRoute("/login")へ
```

---

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 状態管理 | Riverpodでログイン状態を明示的に管理 |
| 自動遷移 | GoRouterの`redirect`で状態に応じてルート切替 |
| UX | SplashScreenでチラつきのない自然な遷移 |
| 再利用性 | どのアプリでも流用可能な汎用的構成 |

この構成により、ログイン状態を常に監視し、  
起動時・ログイン時・ログアウト時の画面遷移を自動化できます。

---
