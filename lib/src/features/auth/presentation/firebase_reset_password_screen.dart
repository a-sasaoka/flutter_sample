import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/auth/firebase_auth_repository.dart';

/// パスワードのリセットメールを送信する画面
class FirebaseResetPasswordScreen extends ConsumerWidget {
  /// コンストラクタ
  const FirebaseResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    // メールアドレスを入力してリセットメールを送る簡易フォーム
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPassword)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: l10n.loginEmailLabel),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Riverpod経由でFirebaseのパスワードリセットを実行
                await ref
                    .read(firebaseAuthRepositoryProvider.notifier)
                    .sendPasswordResetEmail(emailCtrl.text);

                if (context.mounted) {
                  // 送信成功をユーザーに通知
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.resetPasswordMailSent)),
                  );
                }
              },
              child: Text(l10n.send),
            ),
          ],
        ),
      ),
    );
  }
}
