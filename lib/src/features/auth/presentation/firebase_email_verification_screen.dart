import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebaseでメール認証の確認・再送信を行う画面
class FirebaseEmailVerificationScreen extends ConsumerStatefulWidget {
  /// コンストラクタ
  const FirebaseEmailVerificationScreen({super.key});

  @override
  ConsumerState<FirebaseEmailVerificationScreen> createState() =>
      _FirebaseEmailVerificationScreenState();
}

class _FirebaseEmailVerificationScreenState
    extends ConsumerState<FirebaseEmailVerificationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 【自動リロード】スマホの別アプリから戻ってきた時に発火
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(firebaseAuthRepositoryProvider).reloadCurrentUser());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 状態を監視し、emailVerified == true になったら自動で画面遷移
    ref.listen(firebaseAuthStateProvider, (previous, next) {
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

            // PCなどで認証した人向けの「手動リロードボタン」
            FilledButton(
              onPressed: () async {
                // 手動でFirebaseの最新状態を取得しにいく
                await ref
                    .read(firebaseAuthRepositoryProvider)
                    .reloadCurrentUser();
              },
              child: Text(l10n.checkVerificationStatus),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () async {
                await ref
                    .read(firebaseAuthRepositoryProvider)
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
