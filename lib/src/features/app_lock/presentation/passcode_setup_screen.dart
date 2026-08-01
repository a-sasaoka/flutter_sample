import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/widgets/numeric_keyboard.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/widgets/pin_code_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🔐 アプリ起動時・復帰時にパスコードの初期設定を行う画面
class PasscodeSetupScreen extends HookConsumerWidget {
  /// コンストラクタ
  const PasscodeSetupScreen({super.key});

  static const _pinLength = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final firstPin = useState<String>('');
    final confirmPin = useState<String>('');
    final isConfirming = useState<bool>(false);
    final errorMessage = useState<String?>(null);
    final showBiometricPrompt = useState<bool>(false);

    final currentPin = isConfirming.value ? confirmPin.value : firstPin.value;

    Future<void> handleNumberPressed(String number) async {
      if (currentPin.length >= _pinLength) {
        return;
      }

      errorMessage.value = null;

      if (!isConfirming.value) {
        firstPin.value = firstPin.value + number;
        if (firstPin.value.length == _pinLength) {
          isConfirming.value = true;
        }
      } else {
        confirmPin.value = confirmPin.value + number;
        if (confirmPin.value.length == _pinLength) {
          if (firstPin.value == confirmPin.value) {
            // 設定成功
            final notifier = ref.read(appLockServiceProvider.notifier);
            final canCheckBiometrics = await notifier.setupPasscode(
              confirmPin.value,
            );

            if (canCheckBiometrics) {
              showBiometricPrompt.value = true;
            } else {
              notifier.skipBiometric();
            }
          } else {
            // パスコード不一致
            unawaited(HapticFeedback.heavyImpact());
            errorMessage.value = l10n.appLockSetupMismatch;
            firstPin.value = '';
            confirmPin.value = '';
            isConfirming.value = false;
          }
        }
      }
    }

    void handleBackspacePressed() {
      if (currentPin.isNotEmpty) {
        if (!isConfirming.value) {
          firstPin.value = currentPin.substring(0, currentPin.length - 1);
        } else {
          confirmPin.value = currentPin.substring(0, currentPin.length - 1);
        }
      }
    }

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(),
                          Icon(
                            Icons.lock_reset,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.appLockSetupTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isConfirming.value
                                ? l10n.appLockSetupEnterConfirm
                                : l10n.appLockSetupEnterFirst,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          PinCodeField(
                            length: currentPin.length,
                            maxLength: _pinLength,
                          ),
                          const SizedBox(height: 16),
                          AnimatedOpacity(
                            opacity: errorMessage.value != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              errorMessage.value ?? '',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          NumericKeyboard(
                            onNumberPressed: (digit) =>
                                unawaited(handleNumberPressed(digit)),
                            onBackspacePressed: handleBackspacePressed,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 生体認証利用確認のインラインモーダルダイアログ
        if (showBiometricPrompt.value)
          ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.appLockBiometricPromptTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.appLockBiometricPromptMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                showBiometricPrompt.value = false;
                                ref
                                    .read(appLockServiceProvider.notifier)
                                    .skipBiometric();
                              },
                              child: Text(l10n.appLockSkipButton),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                showBiometricPrompt.value = false;
                                await ref
                                    .read(appLockServiceProvider.notifier)
                                    .enableBiometric(
                                      localizedReason:
                                          l10n.appLockBiometricAuthReason,
                                    );
                              },
                              child: Text(l10n.appLockEnableBiometricButton),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
