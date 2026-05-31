import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// パスワードのリセットメールを送信する画面
class FirebaseResetPasswordScreen extends HookConsumerWidget {
  /// コンストラクタ
  const FirebaseResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();

    // ローディング状態を管理するフラグ
    final isLoading = useState(false);

    final l10n = context.l10n;

    // メールアドレスを入力してリセットメールを送る簡易フォーム
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.resetPassword)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.mail_lock_outlined,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.resetPassword,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: l10n.loginEmailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        if (emailCtrl.text.isEmpty) return;

                        isLoading.value = true;
                        try {
                          await ref
                              .read(firebaseAuthRepositoryProvider)
                              .sendPasswordResetEmail(emailCtrl.text);
                          if (context.mounted) {
                            final l10nMessage = l10n.resetPasswordMailSent;
                            context.showSuccessSnackBar(l10nMessage);
                          }
                          if (context.mounted) {
                            context.pop();
                          }
                        } on Exception catch (e) {
                          if (context.mounted) {
                            ErrorHandler.showSnackBar(context, e);
                          }
                        } finally {
                          if (context.mounted) {
                            isLoading.value = false;
                          }
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
                    : const Icon(Icons.send),
                label: Text(l10n.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
