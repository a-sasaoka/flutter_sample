# Firebase Authenticationによる認証対応

このプロジェクトでは、Firebase Authenticationを利用した堅牢な認証機能を追加しています。  
利用できる認証手段としては以下2つに対応しています。

- メールアドレス / パスワード認証

- Googleアカウント（OAuth）

---

## 🏗️ 構成と機能フラグ

本プロジェクトでは、Firebase Authentication を使用するかどうかを `config/flavor_*.json` 内の **`USE_FIREBASE_AUTH`** フラグで制御しています。  
この値は `envConfigProvider` を通じて参照されます。

---

## 📁 関連ファイル構成（レイヤードアーキテクチャ）

```plaintext
lib/src/features/auth/
 ├── data/
 │    └── firebase_auth_repository.dart       # Firebase APIの呼び出し（ログイン・登録）
 └── application/
      └── firebase_auth_state_notifier.dart   # 現在のユーザー(AsyncValue<User?>)の状態管理
```

---

## 💡 Firebase × Riverpod の状態監視（ベストプラクティス）

本プロジェクトの認証状態監視では、Firebase公式の `authStateChanges()` ではなく、あえて **`userChanges()`** を監視（`watch`）しています。実装詳細は [firebase_auth_repository.dart](../lib/src/features/auth/data/firebase_auth_repository.dart)（`authStateChangesProvider`）を参照してください。

- **`user.reload()` との連動**: `user.reload()` が呼ばれた際にも自動的にストリームが発火します。
- **画面遷移時の状態維持**: `@Riverpod(keepAlive: true)` により、画面遷移の合間に状態がリセットされるのを防ぎます。

これにより、「バックグラウンドで `reloadCurrentUser()` を呼ぶだけで、UI側（Riverpod）が自動的にユーザー状態の変更（メール認証完了など）を検知して画面を切り替える」という、非常にクリーンでリアクティブな設計を実現しています。

---

## 🏗️ リポジトリの設計と DI の最適化

`FirebaseAuthRepository` は、Riverpod の環境から独立した**純粋な Dart クラス**として実装されています。

- **コンストラクタ注入**: `FirebaseAuth` や `GoogleSignIn` だけでなく、ロギング用の `Talker` もコンストラクタで直接受け取ります。
- **テスタビリティ**: `Ref` への直接的な依存を排除したことで、モックを用いた単体テストが極めて容易になっています。

---

## 📧 メールアドレスの到達確認（ライフサイクル連動）

メールアドレス/パスワード認証でユーザー登録を行った際は、受診可能なメールアドレスであることを担保するために到達確認を行っています。  
ポーリング（定期通信）による無駄な負荷を避け、**アプリのライフサイクル（フォアグラウンド復帰）と連動したスマートな検知**を実装しています。

### 1. サインアップと確認メールの送信

ユーザー登録画面（[firebase_sign_up_screen.dart](../lib/src/features/auth/presentation/firebase_sign_up_screen.dart)）から `FirebaseAuthRepository.signUp()` および `sendEmailVerification()` を呼び出します。登録が成功すると認証状態の変更をルーター（GoRouter）が検知し、認証ガード（`firebaseAuthGuard`）の働きによって自動的にメール認証画面へリダイレクトされます。

### 2. メールアプリから戻った際の自動チェック（ライフサイクルの監視）

ユーザーが「メールアプリを開いてリンクを踏み、再びこのアプリに戻ってくる」という行動を前提とし、メール認証画面（[firebase_email_verification_screen.dart](../lib/src/features/auth/presentation/firebase_email_verification_screen.dart)）において `appLifecycleProvider` を監視し、**フォアグラウンド復帰時（`AppLifecycleState.resumed`）** に自動で `FirebaseAuthRepository.reloadCurrentUser()` を実行します。

メール認証の完了はルーター（[app_router.dart](../lib/src/app/router/app_router.dart) / `firebaseAuthGuard`）が自動検知してホーム画面（`HomeRoute`）へリダイレクトするため、画面側での監視・手動遷移処理は不要です。

この実装により、無駄な通信を一切行わず、ユーザーがアプリに戻ってきた瞬間にスッと次の画面へ進む最高クラスのUXを提供しています。
（※万が一自動検知から漏れた場合のために、UI側には手動のリロードボタンも完備しています）

---

## 🌐 Googleログイン対応

最新の `google_sign_in` パッケージの仕様に対応し、スコープを用いた安全なトークン取得（`authorizationClient.authorizationForScopes`）を実装しています。  
これにより、iOS/Android 双方で安定したソーシャルログインを提供します。

---

## 🌐 APIリクエストとの統合 (IDトークンの自動付与)

環境設定で `useFirebaseAuth` が `true` に設定されている場合、API通信（Dio）の認証に Firebase Auth の IDトークンが自動的に使用されます。

- **仕組み**: `main.dart` でのアプリ起動時に、通信用のプロバイダ（`tokenStorageProvider` / `tokenRefreshCallbackProvider`）のオーバーライド定義の中で `ref.watch(envConfigProvider)` を監視し、環境フラグに応じてFirebase用の挙動（`FirebaseAuthTokenStorage` 等）に自動で切り替えます。
- **自動付与**: APIを呼び出す際、裏側で `FirebaseAuthTokenStorage` が自動的に `user.getIdToken()` を取得し、 `Authorization: Bearer <IDトークン>` ヘッダーを付与します。
- **自動リフレッシュ**: IDトークンが期限切れになり、APIから `401 Unauthorized` が返ってきた場合は、 `getIdToken(true)` が実行されて強制的にトークンが更新され、自動的に元のAPIリクエストが再試行（リトライ）されます。

詳細は [トークン認証対応（Bearer Token + 自動リフレッシュ）](auth.md) を参照してください。
