import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebase版ログイン画面
class FirebaseLoginScreen extends HookConsumerWidget {
  /// コンストラクタ
  const FirebaseLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();

    // ローディング状態と連打防止のためのフラグ
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: l10n.loginEmailLabel),
              enabled: !isLoading.value, // 通信中は入力不可にする
            ),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 20),

            // メールログインボタン (ローディング対応)
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

                        // 成功 → ホームへ遷移
                        if (context.mounted) {
                          const HomeRoute().go(context);
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showSnackBar(context, e);
                        }
                      } finally {
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
                  : const Icon(Icons.login),
              label: Text(l10n.login),
            ),

            const SizedBox(height: 32),

            // 新規登録画面へ遷移
            OutlinedButton(
              onPressed: isLoading.value
                  ? null
                  : () => const SignUpRoute().push<void>(context),
              child: Text(l10n.signUp),
            ),

            const SizedBox(height: 32),

            // Googleログインボタン (ローディング対応)
            ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      isLoading.value = true;
                      try {
                        final isSignedIn = await ref
                            .read(firebaseAuthRepositoryProvider)
                            .signInWithGoogle();

                        if (!isSignedIn) {
                          return; // ユーザーがキャンセルした場合は何もしない
                        }

                        if (context.mounted) {
                          const HomeRoute().go(context);
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showSnackBar(context, e);
                        }
                      } finally {
                        // キャンセル時やエラー時にも確実にローディングを解除する
                        isLoading.value = false;
                      }
                    },
              child: Text(l10n.googleSignUp),
            ),
          ],
        ),
      ),
    );
  }
}
