# GoRouterを使ったルーティング設定

本プロジェクトでは [GoRouter](https://pub.dev/packages/go_router) を利用し、アプリ全体の画面遷移を管理しています。\
さらに [go_router_builder](https://pub.dev/packages/go_router_builder) を導入し、アノテーションによる**型安全なルーティング定義**を実現しています。

## 主な特徴

- `@TypedGoRoute` アノテーションでルートを定義し、`build_runner` により自動生成。
- 各画面は `GoRouteData` を継承し、IDE補完で安全に遷移可能。
- `const SampleRoute().go(context)` のように記述でき、パス文字列を直接書く必要がありません。
- `routerProvider` により、`Riverpod` 経由で `GoRouter` インスタンスを提供します。

---

### TypedGoRouteの使用例

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

### RiverpodアノテーションによるGoRouter管理

`GoRouter` 設定を Riverpod のアノテーション構文（`@riverpod`）で定義。\
`routerProvider` が自動生成され、明示的な `Provider<GoRouter>` 記述が不要です。

---

## 認証状態管理とルーティング制御（Token Auth / Firebase Auth）

このプロジェクトでは、`GoRouter` の `redirect` を使って、  
認証状態に応じた遷移を自動制御しています。

### 認証モード切替（`USE_FIREBASE_AUTH`）

`app_router.dart` では `AppEnv.useFirebaseAuth` を参照し、利用するガードを切り替えています。

- `USE_FIREBASE_AUTH=true`: `firebaseAuthGuard` を使用
- `USE_FIREBASE_AUTH=false`: `authGuard` を使用（自作認証）

```dart
redirect: (context, state) {
  if (AppEnv.useFirebaseAuth) {
    return firebaseAuthGuard(ref, state);
  }
  return authGuard(ref, state);
},
```

---

### 関連ファイル構成

```plaintext
lib/src/core/auth/
 ├── auth_guard.dart                  # 自作認証向けガード
 ├── auth_state_notifier.dart         # 自作認証の状態管理
 ├── base_auth_guard.dart             # 共通リダイレクト判定ロジック
 ├── firebase_auth_guard.dart         # Firebase認証向けガード
 └── firebase_auth_state_notifier.dart # Firebase認証状態管理

lib/src/features/auth/presentation/
 ├── login_screen.dart                    # 自作認証のログイン画面
 ├── firebase_login_screen.dart           # Firebaseログイン画面
 ├── firebase_sign_up_screen.dart         # Firebaseサインアップ画面
 ├── firebase_email_verification_screen.dart # メール認証待ち画面
 └── firebase_reset_password_screen.dart  # パスワードリセット画面
```

---

### ルートと画面の切替

- `LoginRoute('/login')` は `USE_FIREBASE_AUTH` に応じて表示画面を切り替え
  - `true` のとき: `FirebaseLoginScreen`
  - `false` のとき: `LoginScreen`
- Firebase利用時のみ以下のルートを使用
  - `SignUpRoute('/signup')`
  - `ResetPasswordRoute('/reset-password')`
  - `EmailVerificationRoute('/email-verification')`

---

### 動作フロー

#### `USE_FIREBASE_AUTH=false`（自作認証）

```plaintext
アプリ起動（自作認証版）
   ↓
auth_guard.dart で authStateProvider を監視
   ↓
isLoading の間は SplashRoute("/splash") へ
   ↓
未ログインなら LoginRoute("/login")
ログイン済みなら HomeRoute("/")
```

#### `USE_FIREBASE_AUTH=true`（Firebase認証）

```plaintext
アプリ起動（Firebase認証版）
   ↓
firebase_auth_guard.dart で firebaseAuthStateProvider を監視
   ↓
未ログインなら LoginRoute("/login")
ログイン済みかつメール未認証なら EmailVerificationRoute("/email-verification")
メール認証済みなら HomeRoute("/")
```

---

### メリット

| 項目 | 内容 |
|------|------|
| 状態管理 | Riverpodでログイン状態を明示的に管理 |
| 自動遷移 | GoRouterの`redirect`で状態に応じてルート切替 |
| UX | SplashScreenでチラつきのない自然な遷移 |
| 再利用性 | どのアプリでも流用可能な汎用的構成 |
| 認証方式の切替性 | `USE_FIREBASE_AUTH` の設定で Token Auth と Firebase Auth を切替可能 |

この構成により、ログイン状態を常に監視し、
起動時・ログイン時・ログアウト時の画面遷移を自動化できます。

---
