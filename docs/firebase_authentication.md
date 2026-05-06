# Firebase Authenticationによる認証対応

このプロジェクトでは、Firebase Authenticationを利用した堅牢な認証機能を追加しています。
利用できる認証手段としては以下2つに対応しています。

- メールアドレス / パスワード認証

- Googleアカウント（OAuth）

---

## 🏗️ 構成と機能フラグ

本プロジェクトでは、Firebase Authentication を使用するかどうかを `config/flavor_*.json` 内の **`USE_FIREBASE_AUTH`** フラグで制御しています。この値は `envConfigProvider` を通じて参照されます。

---

## 📁 関連ファイル構成（レイヤードアーキテクチャ）

```plaintext
lib/src/features/auth/
 ├── data/
 │    └── firebase_auth_repository.dart       # Firebase APIの呼び出し（ログイン・登録）
 └── application/
      └── firebase_auth_state_notifier.dart   # 現在のユーザー(User?)の状態管理
```

---

## 💡 Firebase × Riverpod の状態監視（ベストプラクティス）

本プロジェクトの認証状態監視では、Firebase公式の `authStateChanges()` ではなく、あえて **`userChanges()`** を監視（watch）しています。

```dart
// lib/src/features/auth/data/firebase_auth_repository.dart
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  // 💡 user.reload() が呼ばれた時にも自動的にストリームが発火する！
  return ref.watch(firebaseAuthProvider).userChanges();
}
```

これにより、「バックグラウンドで `reloadCurrentUser()` を呼ぶだけで、UI側（Riverpod）が自動的にユーザー状態の変更（メール認証完了など）を検知して画面を切り替える」という、非常にクリーンでリアクティブな設計を実現しています。

---

## 📧 メールアドレスの到達確認（ライフサイクル連動）

メールアドレス/パスワード認証でユーザー登録を行った際は、受診可能なメールアドレスであることを担保するために到達確認を行っています。
ポーリング（定期通信）による無駄な負荷を避け、**アプリのライフサイクル（フォアグラウンド復帰）と連動したスマートな検知**を実装しています。

### 1. サインアップと確認メールの送信

```dart
// lib/src/features/auth/presentation/firebase_sign_up_screen.dart

final authRepo = ref.read(firebaseAuthRepositoryProvider);

// サインアップと確認メール送信
await authRepo.signUp(emailCtrl.text, passwordCtrl.text);
await authRepo.sendEmailVerification();

// メール認証待ち画面へ遷移
if (context.mounted) {
    const FirebaseEmailVerificationRoute().go(context);
}
```

### 2. メールアプリから戻った際の自動チェック（Hooksの活用）

ユーザーが「メールアプリを開いてリンクを踏み、再びこのアプリに戻ってくる」という行動を前提とし、`flutter_hooks` の `useAppLifecycleState` を使って **フォアグラウンド復帰時（resumed）** に自動でリロードをかけます。

```dart
// lib/src/features/auth/presentation/firebase_email_verification_screen.dart

// 💡 1. ライフサイクルを監視
final lifecycleState = useAppLifecycleState();

useEffect(() {
  // アプリに復帰した瞬間に、Firebaseのユーザー状態をリロード
  if (lifecycleState == AppLifecycleState.resumed) {
    unawaited(ref.read(firebaseAuthRepositoryProvider).reloadCurrentUser());
  }
  return null;
}, [lifecycleState]);

// 💡 2. 状態の変更を検知して自動遷移
ref.listen(firebaseAuthStateProvider, (previous, next) {
  if (next != null && next.emailVerified) {
    // 認証完了！ホーム画面へ
    const HomeRoute().go(context);
  }
});
```

この実装により、無駄な通信を一切行わず、ユーザーがアプリに戻ってきた瞬間にスッと次の画面へ進む最高クラスのUXを提供しています。
（※万が一自動検知から漏れた場合のために、UI側には手動のリロードボタンも完備しています）

---

## 🌐 Googleログイン対応

最新の `google_sign_in` パッケージの仕様に対応し、スコープを用いた安全なトークン取得（`authorizationClient.authorizationForScopes`）を実装しています。
これにより、iOS/Android 双方で安定したソーシャルログインを提供します。

---
