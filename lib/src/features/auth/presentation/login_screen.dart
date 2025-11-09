import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/auth/auth_state_notifier.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ログイン画面
class LoginScreen extends ConsumerWidget {
  /// コンストラクタ
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    Future<void> onLogin() async {
      try {
        // 仮のトークンを保存（API連携前提で後で置き換えOK）
        await ref
            .read(authStateProvider.notifier)
            .login(
              'dummy_access_token',
              'dummy_refresh_token',
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログイン成功！')),
          );
        }
      } on Exception catch (e) {
        if (context.mounted) {
          await ErrorHandler.showDialogError(context, e);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onLogin,
              child: const Text('ログイン'),
            ),
          ],
        ),
      ),
    );
  }
}
