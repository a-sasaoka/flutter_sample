import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/auth/firebase_auth_repository.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Firebase版のサインアップ画面
class FirebaseSignUpScreen extends ConsumerStatefulWidget {
  /// コンストラクタ
  const FirebaseSignUpScreen({super.key});

  @override
  ConsumerState<FirebaseSignUpScreen> createState() =>
      _FirebaseSignUpScreenState();
}

class _FirebaseSignUpScreenState extends ConsumerState<FirebaseSignUpScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
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

            // 登録ボタン
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        await ref
                            .read(firebaseAuthRepositoryProvider.notifier)
                            .signUp(emailCtrl.text, passwordCtrl.text);

                        // 登録成功 → ホーム画面へ遷移
                        if (context.mounted) {
                          const HomeRoute().go(context);
                        }
                      } on Exception catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.errorSignUpFailed)),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: Text(
                isLoading ? l10n.loading : l10n.signUp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
