import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/widgets/numeric_keyboard.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/widgets/pin_code_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🔐 アプリ起動時・復帰時に表示されるパスコード入力・生体認証ロック画面
class PasscodeLockScreen extends HookConsumerWidget {
  /// コンストラクタ
  const PasscodeLockScreen({
    required this.isBiometricEnabled,
    super.key,
  });

  /// 生体認証が有効かどうか
  final bool isBiometricEnabled;
  static const _pinLength = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final inputPin = useState<String>('');
    final errorMessage = useState<String?>(null);
    final isAuthenticating = useState<bool>(false);

    // 生体認証ダイアログの自動起動
    useEffect(
      () {
        if (!isBiometricEnabled) {
          return null;
        }

        Future<void> triggerBiometric() async {
          isAuthenticating.value = true;
          try {
            await ref
                .read(appLockServiceProvider.notifier)
                .unlockWithBiometrics(
                  localizedReason: l10n.appLockBiometricAuthReason,
                );
          } finally {
            if (context.mounted) {
              isAuthenticating.value = false;
            }
          }
        }

        unawaited(triggerBiometric());
        return null;
      },
      const [],
    );

    /// ユーザーがキーパッド左下の生体認証ボタンをタップした時に呼び出す
    Future<void> handleBiometricPressed() async {
      if (isAuthenticating.value) return;

      isAuthenticating.value = true;
      try {
        await ref
            .read(appLockServiceProvider.notifier)
            .unlockWithBiometrics(
              localizedReason: l10n.appLockBiometricAuthReason,
            );
      } finally {
        if (context.mounted) {
          isAuthenticating.value = false;
        }
      }
    }

    Future<void> handleNumberPressed(String number) async {
      if (inputPin.value.length >= _pinLength) {
        return;
      }

      errorMessage.value = null;
      final newPin = inputPin.value + number;
      inputPin.value = newPin;

      if (newPin.length == _pinLength) {
        final result = await ref
            .read(appLockServiceProvider.notifier)
            .unlockWithPasscode(newPin);

        switch (result) {
          case UnlockResultSuccess():
            break;
          case UnlockResultInvalidPasscode():
            unawaited(HapticFeedback.heavyImpact());
            errorMessage.value = l10n.appLockPasscodeIncorrect;
            inputPin.value = '';
          case UnlockResultLockedOut(:final lockedOutUntil):
            unawaited(HapticFeedback.heavyImpact());
            final now = ref.read(clockProvider)();
            final remainingSeconds = math.max(
              1,
              lockedOutUntil.difference(now).inSeconds,
            );
            errorMessage.value = l10n.appLockLockedOut(remainingSeconds);
            inputPin.value = '';
        }
      }
    }

    void handleBackspacePressed() {
      if (inputPin.value.isNotEmpty) {
        inputPin.value = inputPin.value.substring(0, inputPin.value.length - 1);
      }
    }

    return AbsorbPointer(
      absorbing: isAuthenticating.value,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
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
                          Icons.security,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.appLockEnterPasscodeTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        PinCodeField(
                          length: inputPin.value.length,
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
                          onBiometricPressed: isBiometricEnabled
                              ? () => unawaited(handleBiometricPressed())
                              : null,
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
    );
  }
}
