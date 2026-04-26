import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
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
              // 通信中は入力をロックする
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 20),

            // ボタンを FilledButton.icon にし、ローディングUIを組み込む
            FilledButton.icon(
              onPressed: isLoading.value
                  ? null // 通信中はボタンを無効化（連打防止）
                  : () async {
                      // 未入力の場合は弾く（簡易バリデーション）
                      if (emailCtrl.text.isEmpty) return;

                      isLoading.value = true;
                      try {
                        // Riverpod経由でFirebaseのパスワードリセットを実行
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .sendPasswordResetEmail(emailCtrl.text);

                        if (context.mounted) {
                          context
                            ..showSuccessSnackBar(
                              l10n.resetPasswordMailSent,
                            )
                            ..pop();
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
                  : const Icon(Icons.send),
              label: Text(l10n.send),
            ),
          ],
        ),
      ),
    );
  }
}
