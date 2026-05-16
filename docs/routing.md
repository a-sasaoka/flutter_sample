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
// lib/src/app/router/routes/home_routes.dart (分割管理の例)

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

`GoRouter` 設定を Riverpod のアノテーション構文（`@riverpod`）で定義。
`routerProvider` が自動生成され、明示的な `Provider<GoRouter>` 記述が不要です。

---

## 認証状態管理とルーティング制御（AuthGuard + SplashScreen）

このプロジェクトでは、`AuthStateNotifier` と `GoRouter` の `redirect` 機能を組み合わせ、ログイン状態に応じて画面遷移を自動制御しています。\
さらに、状態判定中のチラつきを防ぐために `SplashScreen` を導入しています。

### 🛡️ 柔軟な AuthGuard 設計（Firebase / 独自トークン両対応）

本プロジェクトの最大の強みは、認証ガード（AuthGuard）が抽象化されている点です。
公開設定（JSON）の `USE_FIREBASE_AUTH` の値に応じて、**「Firebase認証用のガード」と「Bearerトークン認証用のガード」を自動的に切り替える**仕組みが組み込まれています。

また、`AuthGuardHelper` は特定の画面定義に依存しないよう設計されており、初期化時に「ログイン画面」や「ホーム画面」のパスを渡すことで、プロジェクト間での再利用性が高い汎用的な門番として機能します。

---

### 📁 関連ファイル構成

ルーティング関連のコードは、保守性を高めるために機能ごとの定義（Routes）と生成ロジック（Router）に分離されています。

```plaintext
lib/src/app/router/
 ├── app_router.dart                    # GoRouterのメイン定義（part構文でRoutesを結合）
 ├── routes/                            # 親ルートごとに分割された定義ファイル
 │    ├── auth_routes.dart             # ログイン・サインアップ系
 │    ├── home_routes.dart             # ホーム・各機能画面系
 │    └── splash_routes.dart           # スプラッシュ画面
 ├── base_auth_guard.dart               # 認証ガードの基底クラス（リダイレクト制御の共通化）
 ├── auth_guard.dart                    # Bearerトークンベースの認証ガード
 └── firebase_auth_guard.dart           # Firebase Authentication用の認証ガード
```

---

### 💡 コードの分割管理（part / part of 構文）

本プロジェクトでは、`go_router_builder` による型安全性を維持しつつ、巨大なルート定義ファイルを避けるために Dart の **`part` / `part of` 構文** を採用しています。

- **メリット**:
  - `auth_routes.dart` 等の各ファイルは、親である `app_router.dart` の一部として扱われるため、インポート文を重複させる必要がありません。
  - 生成される `app_router.g.dart` は1つのままであるため、外部からは分割を意識せずに `HomeRoute().go(context)` といった型安全な遷移コードを利用できます。
  - 機能追加時に編集すべきファイルが明確になり、コンフリクトのリスクを低減します。

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

## 🛠️ 画面遷移時の共通処理（NavigatorObserver）

本プロジェクトでは、画面遷移をフックして共通の処理を行うために `NavigatorObserver` を活用しています。

### 🚀 スナックバーの自動消去 (SnackBarNavigationObserver)

Flutterのデフォルト仕様では、画面遷移してもスナックバーが残り続けてしまいます。これを防ぐため、遷移（Push/Pop）が発生したタイミングで表示中のスナックバーをすべて自動消去する仕組みを導入しています。

- **実装場所**: `lib/src/app/router/snackbar_navigation_observer.dart`
- **仕組み**:
  1. `scaffoldMessengerKey` を `MaterialApp` に登録。
  2. `GoRouter` の `observers` に `SnackBarNavigationObserver` を追加。
  3. 遷移のたびに `scaffoldMessengerKey.currentState?.clearSnackBars()` を実行。

これにより、開発者が各画面で手動でお掃除コードを書く手間とミスを排除しています。

---
