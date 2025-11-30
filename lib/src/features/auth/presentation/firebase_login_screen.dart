import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/auth/firebase_auth_repository.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebase版ログイン画面
class FirebaseLoginScreen extends ConsumerStatefulWidget {
  /// コンソトラクタ
  const FirebaseLoginScreen({super.key});

  @override
  ConsumerState<FirebaseLoginScreen> createState() =>
      _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends ConsumerState<FirebaseLoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: l10n.loginEmailLabel),
            ),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(firebaseAuthRepositoryProvider.notifier)
                      .signIn(
                        emailCtrl.text,
                        passwordCtrl.text,
                      );

                  // 成功 → ホームへ遷移
                  if (context.mounted) {
                    const HomeRoute().go(context);
                  }
                } on Exception catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorLoginFailed)),
                    );
                  }
                }
              },
              child: Text(l10n.login),
            ),
          ],
        ),
      ),
    );
  }
}
