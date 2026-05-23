import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebase版のサインアップ画面
class FirebaseSignUpScreen extends HookConsumerWidget {
  /// コンストラクタ
  const FirebaseSignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();

    // ローディング状態を管理するフラグ
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.person_add_outlined,
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

            FilledButton.icon(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                        return;
                      }

                      isLoading.value = true;
                      try {
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .signUp(emailCtrl.text, passwordCtrl.text);

                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .sendEmailVerification();
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
                  : const Icon(Icons.person_add),
              label: Text(l10n.signUp),
            ),

            const SizedBox(height: 16),

            // ログイン画面へ戻るボタン
            TextButton.icon(
              onPressed: isLoading.value ? null : () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.login),
            ),
          ],
        ),
      ),
    );
  }
}
