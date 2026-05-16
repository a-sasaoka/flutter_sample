import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
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
    final l10n = context.l10n;

    // ローディング状態を管理するフックを追加
    final isReloading = useState(false);
    final isResending = useState(false);

    ref
      ..listen(appLifecycleProvider, (previous, next) {
        if (next == AppLifecycleState.resumed) {
          unawaited(
            () async {
              try {
                await ref
                    .read(firebaseAuthRepositoryProvider)
                    .reloadCurrentUser();
              } on Exception catch (e) {
                if (context.mounted) {
                  ErrorHandler.showSnackBar(context, e);
                }
              }
            }(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.mark_email_read_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.emailVerificationTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emailVerificationDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 手動リロードボタン
            FilledButton.icon(
              onPressed: isReloading.value || isResending.value
                  ? null
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
                        if (context.mounted) {
                          isReloading.value = false;
                        }
                      }
                    },
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

            // 再送信ボタン
            OutlinedButton.icon(
              onPressed: isReloading.value || isResending.value
                  ? null
                  : () async {
                      isResending.value = true;
                      try {
                        await ref
                            .read(firebaseAuthRepositoryProvider)
                            .sendEmailVerification();

                        if (context.mounted) {
                          context.showSuccessSnackBar(
                            l10n.resendVerificationMailSuccess,
                          );
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showSnackBar(context, e);
                        }
                      } finally {
                        if (context.mounted) {
                          isResending.value = false;
                        }
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

            const SizedBox(height: 24),

            Text(
              l10n.emailVerificationWaiting,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // サインアウトして戻るボタン
            TextButton.icon(
              onPressed: () async {
                await ref.read(firebaseAuthRepositoryProvider).signOut();
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
            ),
          ],
        ),
      ),
    );
  }
}
