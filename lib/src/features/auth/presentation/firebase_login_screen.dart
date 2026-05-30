import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebase版ログイン画面
class FirebaseLoginScreen extends HookConsumerWidget {
  /// コンストラクタ
  const FirebaseLoginScreen({super.key}); // coverage:ignore-line

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();

    // ローディング状態と連打防止のためのフラグ
    final isLoading = useState(false);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.loginTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: l10n.loginEmailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.loginPasswordLabel,
                  prefixIcon: const Icon(Icons.password_outlined),
                ),
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 24),

              // メールログインボタン
              FilledButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        isLoading.value = true;
                        try {
                          await ref
                              .read(firebaseAuthRepositoryProvider)
                              .signIn(
                                emailCtrl.text,
                                passwordCtrl.text,
                              );
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
                    : const Icon(Icons.login),
                label: Text(l10n.login),
              ),

              const SizedBox(height: 16),

              // Googleログインボタン
              ElevatedButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        isLoading.value = true;
                        try {
                          final isSignedIn = await ref
                              .read(firebaseAuthRepositoryProvider)
                              .signInWithGoogle();

                          if (!isSignedIn) return;
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_circle_outlined),
                label: Text(l10n.googleSignUp),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 新規登録画面へ遷移
              OutlinedButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () => const SignUpRoute().push<void>(context),
                icon: const Icon(Icons.person_add_outlined),
                label: Text(l10n.signUp),
              ),

              const SizedBox(height: 8),

              // パスワードリセット画面へ遷移
              TextButton(
                onPressed: isLoading.value
                    ? null
                    : () => const ResetPasswordRoute().push<void>(context),
                child: Text(l10n.resetPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
