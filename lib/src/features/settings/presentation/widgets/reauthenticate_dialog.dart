import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/form_validators.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// アカウント削除前の本人確認（再認証）ダイアログを表示するユーティリティ
abstract final class ReauthenticateDialog {
  /// 再認証モーダルを表示し、再認証に成功した場合のみ true を返す
  static Future<bool> show(
    BuildContext context, {
    required Set<ReauthMethod> availableMethods,
    required Future<void> Function(String password, String? email)
    onPasswordSubmit,
    required Future<void> Function() onGoogleSubmit,
    String? email,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReauthenticateDialogContent(
        availableMethods: availableMethods,
        onPasswordSubmit: onPasswordSubmit,
        onGoogleSubmit: onGoogleSubmit,
        email: email,
      ),
    );
    return result ?? false;
  }
}

/// 本人確認（再認証）ダイアログの表示内容ウィジェット
///
/// 連携済みプロバイダに応じてパスワード入力・Google再認証・両方切替を自動出し分けし、
/// パスワード誤りや `user-mismatch` 等が発生した際はダイアログ内で再試行できます。
class ReauthenticateDialogContent extends HookWidget {
  /// コンストラクタ
  const ReauthenticateDialogContent({
    required this.availableMethods,
    required this.onPasswordSubmit,
    required this.onGoogleSubmit,
    this.email,
    this.initialErrorMessage,
    this.initialSelectedMethod,
    super.key,
  });

  /// 利用可能な再認証手段
  final Set<ReauthMethod> availableMethods;

  /// パスワード再認証実行コールバック
  final Future<void> Function(String password, String? email) onPasswordSubmit;

  /// Google再認証実行コールバック
  final Future<void> Function() onGoogleSubmit;

  /// 現在のアカウントメールアドレス（取得できない場合は null または空）
  final String? email;

  /// ゴールデンテスト等の初期表示用エラーメッセージ
  final String? initialErrorMessage;

  /// ゴールデンテスト等の初期選択認証方式
  final ReauthMethod? initialSelectedMethod;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (availableMethods.isEmpty) {
      return AlertDialog(
        title: Text(l10n.reauthDialogTitle),
        content: Text(l10n.reauthUnavailableProvider),
        actions: [
          TextButton(
            key: const Key('reauth_close_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.close),
          ),
        ],
      );
    }

    final defaultMethod =
        initialSelectedMethod != null &&
            availableMethods.contains(initialSelectedMethod)
        ? initialSelectedMethod!
        : (availableMethods.contains(ReauthMethod.password)
              ? ReauthMethod.password
              : ReauthMethod.google);

    final selectedMethod = useState(defaultMethod);
    final isSubmitting = useState(false);
    final obscurePassword = useState(true);
    final errorMessage = useState<String?>(initialErrorMessage);

    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    final hasEmail = email != null && email!.isNotEmpty;

    Future<void> runReauth(Future<void> Function() action) async {
      errorMessage.value = null;
      isSubmitting.value = true;
      try {
        await action();
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      } on Exception catch (e) {
        if (context.mounted) {
          errorMessage.value = ErrorHandler.message(context, e);
        }
      } finally {
        if (context.mounted) {
          isSubmitting.value = false;
        }
      }
    }

    Future<void> handlePasswordSubmit() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }
      final resolvedEmail = hasEmail ? email : emailController.text.trim();
      await runReauth(
        () => onPasswordSubmit(passwordController.text, resolvedEmail),
      );
    }

    return PopScope(
      canPop: !isSubmitting.value,
      child: AlertDialog(
        title: Text(l10n.reauthDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reauthDialogDescription),
              if (availableMethods.length > 1) ...[
                const SizedBox(height: 16),
                SegmentedButton<ReauthMethod>(
                  key: const Key('reauth_method_selector'),
                  segments: [
                    ButtonSegment(
                      value: ReauthMethod.password,
                      label: Text(l10n.reauthPasswordTab),
                      icon: const Icon(Icons.password),
                    ),
                    ButtonSegment(
                      value: ReauthMethod.google,
                      label: Text(l10n.reauthGoogleTab),
                      icon: const Icon(Icons.g_mobiledata),
                    ),
                  ],
                  selected: {selectedMethod.value},
                  onSelectionChanged: isSubmitting.value
                      ? null
                      : (selection) {
                          selectedMethod.value = selection.first;
                          errorMessage.value = null;
                        },
                ),
              ],
              if (errorMessage.value case final message?) ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  key: const Key('reauth_error_banner'),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (selectedMethod.value == ReauthMethod.password)
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasEmail) ...[
                        Text(
                          l10n.reauthTargetEmailLabel(email!),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        TextFormField(
                          key: const Key('reauth_email_field'),
                          controller: emailController,
                          enabled: !isSubmitting.value,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.loginEmailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                              errorText: l10n.validationEmailRequired,
                            ),
                            FormValidators.notOnlyWhitespace(
                              errorText: l10n.validationNotOnlyWhitespace,
                            ),
                            FormBuilderValidators.email(
                              errorText: l10n.validationEmailInvalid,
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        key: const Key('reauth_password_field'),
                        controller: passwordController,
                        enabled: !isSubmitting.value,
                        obscureText: obscurePassword.value,
                        decoration: InputDecoration(
                          labelText: l10n.loginPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            key: const Key('reauth_password_visibility_toggle'),
                            onPressed: () {
                              obscurePassword.value = !obscurePassword.value;
                            },
                            icon: Icon(
                              obscurePassword.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                            errorText: l10n.validationPasswordRequired,
                          ),
                          FormValidators.notOnlyWhitespace(
                            errorText: l10n.validationNotOnlyWhitespace,
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('reauth_password_submit_button'),
                        onPressed: isSubmitting.value
                            ? null
                            : handlePasswordSubmit,
                        child: isSubmitting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.reauthPasswordSubmit),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  key: const Key('reauth_google_submit_button'),
                  onPressed: isSubmitting.value
                      ? null
                      : () => runReauth(onGoogleSubmit),
                  icon: isSubmitting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata),
                  label: Text(l10n.reauthGoogleSubmit),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('reauth_cancel_button'),
            onPressed: isSubmitting.value
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
