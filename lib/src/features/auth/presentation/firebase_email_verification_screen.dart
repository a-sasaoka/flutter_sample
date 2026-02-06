import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/auth/firebase_auth_repository.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebaseでメール認証の確認・再送信を行う画面
///
/// この画面では以下を行う:
/// - メール確認待ちの説明表示
/// - 認証メールの再送信
/// - 一定間隔でユーザー情報をリロードし、
///   emailVerified が true になったら自動で Home へ遷移
class FirebaseEmailVerificationScreen extends ConsumerStatefulWidget {
  /// コンストラクタ
  const FirebaseEmailVerificationScreen({super.key});

  @override
  ConsumerState<FirebaseEmailVerificationScreen> createState() =>
      _FirebaseEmailVerificationScreenState();
}

class _FirebaseEmailVerificationScreenState
    extends ConsumerState<FirebaseEmailVerificationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // 3秒ごとにメール認証状態をチェック
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final authRepo = ref.read(firebaseAuthRepositoryProvider.notifier);

      await authRepo.reloadCurrentUser();
      if (!mounted) return;

      final user = ref.watch(firebaseAuthRepositoryProvider);
      if (user != null && user.emailVerified) {
        _timer?.cancel();

        // メール確認完了 → ホーム画面へ遷移
        if (!mounted) return;
        const HomeRoute().go(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailVerificationTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.emailVerificationDescription),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                // 現在のユーザーに認証メールを再送する
                await ref
                    .read(firebaseAuthRepositoryProvider.notifier)
                    .sendEmailVerification();
              },
              child: Text(l10n.resendVerificationMail),
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
