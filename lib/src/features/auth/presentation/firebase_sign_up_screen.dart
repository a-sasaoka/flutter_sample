import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebase版のサインアップ画面
class FirebaseSignUpScreen extends HookConsumerWidget {
  /// コンストラクタ
  const FirebaseSignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();

    // ローディング状態を管理するフラグ
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: l10n.loginEmailLabel),
              enabled: !isLoading.value, // 通信中は入力をロック
            ),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
              enabled: !isLoading.value, // 通信中は入力をロック
            ),
            const SizedBox(height: 20),

            // ボタンを FilledButton.icon に変更し、共通のローディングUIに
            FilledButton.icon(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      // 簡易バリデーション
                      if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                        return;
                      }

                      isLoading.value = true;

                      try {
                        // サインアップ
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .signUp(emailCtrl.text, passwordCtrl.text);

                        // 確認メール送信
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .sendEmailVerification();

                        // メール認証待ち画面へ遷移
                        if (context.mounted) {
                          const EmailVerificationRoute().go(context);
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showSnackBar(context, e);
                        }
                      } finally {
                        // 画面遷移後やエラー後にも確実にローディングを解除する
                        isLoading.value = false;
                      }
                    },
              icon: isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(l10n.signUp),
            ),
          ],
        ),
      ),
    );
  }
}
