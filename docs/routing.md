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
// lib/src/app/router/routes/home_tab_routes.dart (分割管理の例)

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

### 🔄 共通リダイレクト判定処理 (`checkBaseRedirect`)

複数の認証ガード（通常の `authGuard` と Firebase用の `firebaseAuthGuard`）で重複していた、以下の初期状態や共通画面へのリダイレクト判定ロジックを [base_auth_guard.dart](base_auth_guard.dart) の `checkBaseRedirect` 関数に共通化しています。

1. **スプラッシュ画面の表示完了待ち**: スプラッシュのアニメーションが完了するまで他の画面に遷移させない制御。
2. **オンボーディング（チュートリアル）の完了確認**: 初回起動時のオンボーディングデータの読み込み状態やエラー、および未完了時のオンボーディング画面への強制誘導。
3. **初期表示の振り分け**: スプラッシュ画面やオンボーディング画面から、ログイン状態（`isLoggedIn`）に応じた「ホーム」または「ログイン」へのリダイレクト。

これにより、各ガードファイルはそれぞれの認証プロバイダからの状態取得や、Firebase固有の「メール未認証チェック」などの固有ロジックだけに集中できる、保守性の高い構成になっています。

### 🛡️ 柔軟な AuthGuard 設計とスマートなリダイレクト

本プロジェクトの最大の強みは、認証ガード（AuthGuard）が抽象化されている点と、**「ログイン後に元の画面へ戻す」優れたUX**を備えている点です。

#### 1. ガードロジックの汎用化と明瞭なカテゴリ分け

`AuthGuardHelper` は特定の画面定義に依存しないよう設計されており、初期化時に以下の3つのカテゴリにパスを分類して渡すことで、プロジェクト間での再利用性が高い汎用的な門番として機能します。

- **`alwaysPublicPaths`**: 常に誰でもアクセス可能な画面（スプラッシュなど）
- **`guestOnlyPaths`**: 未ログイン時のみアクセス可能な画面（ログイン、サインアップなど）。ログイン済みユーザーはホーム等へリダイレクトされます。
- **上記以外**: 認証必須画面として扱われ、未ログイン時はログイン画面へリダイレクトされます。

#### 2. `from` パラメータによる元の画面への自動復帰

ユーザーが未ログインの状態で認証必須の画面（例：`/settings`）に直接アクセスした場合、ガードが発動してログイン画面へ飛ばされます。\
この際、`AuthGuardHelper` は元の目的地を `from` クエリパラメータとして付与します（例：`/login?from=/settings`）。

ユーザーがログインを完了すると、ルーターがこれを検知し、`from` パラメータの場所へ自動的にリダイレクトさせます。これにより、ユーザーは迷うことなく本来の目的に復帰できます。

#### 3. Firebase / 独自トークン両対応

公開設定（JSON）の `USE_FIREBASE_AUTH` の値に応じて、「Firebase認証用のガード（サインアップ画面等を含む）」と「Bearerトークン認証用のガード」を自動的に切り替える仕組みが組み込まれています。

---

### 📁 関連ファイル構成

ルーティング関連のコードは、保守性を高めるために機能ごとの定義（Routes）と生成ロジック（Router）に分離されています。

```plaintext
lib/src/app/router/
 ├── app_router.dart                    # GoRouterのメイン定義（part構文でRoutesを結合）
 ├── routes/                            # 各機能・タブごとに分割された定義ファイル
 │    ├── auth_routes.dart             # ログイン・サインアップ系
 │    ├── chat_tab_routes.dart         # AIチャットタブのルート定義
 │    ├── chart_tab_routes.dart        # グラフタブのルート定義
 │    ├── home_tab_routes.dart         # ホームタブのルート定義
 │    ├── memos_tab_routes.dart        # メモタブのルート定義
 │    ├── onboarding_routes.dart       # オンボーディング画面のルート定義
 │    ├── shell_routes.dart            # ナビゲーションシェル（ボトムメニュー）の定義
 │    ├── splash_routes.dart           # スプラッシュ画面の定義
 │    └── user_tab_routes.dart         # ユーザー一覧タブのルート定義
 ├── base_auth_guard.dart               # 共通リダイレクト判定処理（checkBaseRedirect）と共通ヘルパー
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

### 🧪 動作フローとスプラッシュ画面表示時間保証

スプラッシュ画面のチラつきを防ぎ、かつリッチなアニメーション（最低2秒）をユーザーに確実に見せるため、以下のフローで制御を行っています。

```plaintext
アプリ起動（初期ルートは /splash）
   ↓
SplashScreen表示 ＆ アニメーション開始（最低2秒間表示）
   ↓
2秒経過後にスプラッシュ完了（splashStateProvider = true に更新）
   ↓
GoRouter のリダイレクト処理（authGuard / firebaseAuthGuard）が再評価
   ↓
現在地が /splash かつスプラッシュ完了済みの場合：
   ├─【認証済み】 ──→ HomeRoute("/") へ自動遷移
   └─【未認証】   ──→ LoginRoute("/login") へ自動遷移
```

この制御を行うため、`app_router.dart` 内で `splashStateProvider` をリッスンし、状態が完了（`true`）に変わったタイミングでルーターの更新（リダイレクト処理の再判定をトリガー）を行っています。

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

Flutterのデフォルト仕様では、画面遷移してもスナックバーが残り続けてしまいます。これを防ぐため、画面遷移が発生したタイミングで表示中のスナックバーをすべて自動消去する仕組みを導入しています。

- **実装場所**: `lib/src/app/router/snackbar_navigation_observer.dart`
- **特徴**:
  - **DIの徹底**: コンストラクタで `scaffoldMessengerKey` を受け取り、テスト容易性を確保しています。
  - **網羅的な検知**: `didPush`, `didPop` に加え、`context.go()` などで使用される `didReplace` にも対応しています。
  - **スマートな判定**: `PageRoute`（通常の画面）の遷移時のみ消去し、ダイアログやボトムシート（`PopupRoute`）の開閉時にはスナックバーを維持するように工夫されています。
- **仕組み**:
  1. `scaffoldMessengerKey` を `MaterialApp` に登録。
  2. `GoRouter` の `observers` に `SnackBarNavigationObserver(scaffoldMessengerKey)` を追加。

これにより、開発者が各画面で手動でお掃除コードを書く手間とミスを排除しています。

---

## 🔗 関連ドキュメント

ディープリンク（Custom URL Scheme / App Links）の連携設定や詳細な動作フローについては、以下を参照してください。

- [DeepLink（ディープリンク）設定](deeplink.md)
