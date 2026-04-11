import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/core/utils/app_lifecycle_provider.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebaseでメール認証の確認・再送信を行う画面
class FirebaseEmailVerificationScreen extends HookConsumerWidget {
  /// コンストラクタ
  const FirebaseEmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // ローディング状態を管理するフックを追加
    final isReloading = useState(false);
    final isResending = useState(false);

    ref
      ..listen(appLifecycleProvider, (previous, next) {
        if (next == AppLifecycleState.resumed) {
          unawaited(
            ref.read(firebaseAuthRepositoryProvider).reloadCurrentUser(),
          );
        }
      })
      ..listen(firebaseAuthStateProvider, (previous, next) {
        if (next != null && next.emailVerified) {
          const HomeRoute().go(context);
        }
      });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailVerificationTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.emailVerificationDescription),
            const SizedBox(height: 24),

            // 手動リロードボタン（ローディングとエラーハンドリング対応）
            FilledButton.icon(
              onPressed: isReloading.value || isResending.value
                  ? null // 処理中はボタンを無効化（連打防止）
                  : () async {
                      isReloading.value = true;
                      try {
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .reloadCurrentUser();
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showSnackBar(context, e);
                        }
                      } finally {
                        isReloading.value = false;
                      }
                    },
              // 処理中はインジケーターを表示
              icon: isReloading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.checkVerificationStatus),
            ),

            const SizedBox(height: 16),

            // 再送信ボタン（成功フィードバックとエラーハンドリング対応）
            OutlinedButton.icon(
              onPressed: isReloading.value || isResending.value
                  ? null
                  : () async {
                      isResending.value = true;
                      try {
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .sendEmailVerification();

                        // 成功したことをユーザーに伝える！
                        if (context.mounted) {
                          context.showSuccessSnackBar(
                            l10n.emailVerificationDescription,
                          );
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showSnackBar(context, e);
                        }
                      } finally {
                        isResending.value = false;
                      }
                    },
              icon: isResending.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mail_outline),
              label: Text(l10n.resendVerificationMail),
            ),

            const SizedBox(height: 16),

            Text(
              l10n.emailVerificationWaiting,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
