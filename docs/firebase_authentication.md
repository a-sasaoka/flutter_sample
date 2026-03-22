# Firebase Authenticationによる認証対応

このプロジェクトでは、Firebase Authenticationを利用した認証機能を追加しています。  
利用できる認証手段としては以下2つに対応しています。

- メールアドレス/パスワード認証
- Googleアカウント

## メールアドレスの到達確認

メールアドレス/パスワード認証でユーザー登録を行った際はメールアドレスの到達確認を行っています。  
この処理により受診可能なメールアドレスで登録されたことを担保しています。

```dart
// lib/src/features/auth/presentation/firebase_sign_up_screen.dart

// サインアップ
await ref
    .read(firebaseAuthRepositoryProvider.notifier)
    .signUp(emailCtrl.text, passwordCtrl.text);

// 確認メール送信
await ref
    .read(firebaseAuthRepositoryProvider.notifier)
    .sendEmailVerification();

// メール認証待ち画面へ遷移
if (context.mounted) {
    const EmailVerificationRoute().go(context);
}
```

```dart
// lib/src/features/auth/presentation/firebase_email_verification_screen.dart

// 3秒ごとにメール認証状態をチェック
_timer = Timer.periodic(const Duration(seconds: 3), (_) async {
    final authRepo = ref.read(firebaseAuthRepositoryProvider.notifier);

    await authRepo.reloadCurrentUser();
    if (!mounted) return;

    final user = ref.read(firebaseAuthRepositoryProvider);
    if (user != null && user.emailVerified) {
    _timer?.cancel();

    // メール確認完了 → ホーム画面へ遷移
    if (!mounted) return;
    const HomeRoute().go(context);
    }
});
```

---
