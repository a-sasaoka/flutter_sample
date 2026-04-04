import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ログイン画面
class LoginScreen extends HookConsumerWidget {
  /// コンストラクタ
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // useTextEditingController() を使うことで、画面が再描画されても
    // コントローラーが作り直されず、中のデータが保たれます
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    // ローディング状態の管理を追加
    final isLoading = useState(false);

    final l10n = AppLocalizations.of(context)!;

    Future<void> onLogin() async {
      // 簡易バリデーション（空なら弾く）
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        return;
      }

      isLoading.value = true;
      try {
        // 仮のトークンを保存（API連携前提で後で置き換えOK）
        await ref
            .read(authStateProvider.notifier)
            .login(
              'dummy_access_token',
              'dummy_refresh_token',
            );

        if (context.mounted) {
          context.showSuccessSnackBar(l10n.loginSuccess);

          final analytics = ref.read(analyticsServiceProvider);
          await analytics.logEvent(
            event: AnalyticsEvent.loginSuccess,
          );
        }
      } on Exception catch (e) {
        if (context.mounted) {
          await ErrorHandler.showDialogError(context, e);
        }
      } finally {
        // 処理完了後（成功・失敗問わず）にローディングを解除
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.loginEmailLabel,
              ),
              enabled: !isLoading.value, // 通信中は入力をロック
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: l10n.loginPasswordLabel,
              ),
              obscureText: true,
              enabled: !isLoading.value, // 通信中は入力をロック
            ),
            const SizedBox(height: 16),

            // ボタンを FilledButton.icon にして、他の画面とUIを統一
            FilledButton.icon(
              onPressed: isLoading.value ? null : onLogin,
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
              label: Text(l10n.loginButton),
            ),
          ],
        ),
      ),
    );
  }
}
