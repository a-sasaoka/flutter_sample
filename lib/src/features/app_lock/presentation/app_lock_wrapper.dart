import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/utils/app_lifecycle_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_lock_screen.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_setup_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🔐 アプリ全体を包み込み、最前面にロックオーバーレイを描画＆ライフサイクル監視を行うラッパー
class AppLockWrapper extends ConsumerWidget {
  /// コンストラクタ
  const AppLockWrapper({
    required this.child,
    super.key,
  });

  /// ラップする子ウィジェット
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockAsync = ref.watch(appLockServiceProvider);

    // アプリのライフサイクル（バックグラウンド復帰）監視
    ref.listen(appLifecycleProvider, (previous, next) {
      if (next == AppLifecycleState.resumed) {
        ref.read(appLockServiceProvider.notifier).lockApp();
      }
    });

    return Stack(
      children: [
        // 通常のアプリコンテンツ
        child,

        // アプリロック状態に応じた最前面オーバーレイ
        switch (appLockAsync) {
          AsyncData(:final value) => switch (value) {
            AppLockStateDisabled() ||
            AppLockStateUnlocked() => const SizedBox.shrink(),
            AppLockStateSetupRequired() => const PasscodeSetupScreen(),
            AppLockStateLocked(:final isBiometricEnabled) => PasscodeLockScreen(
              isBiometricEnabled: isBiometricEnabled,
            ),
          },
          AsyncLoading() => ColoredBox(
            key: const Key('app_lock_loading_shield'),
            color: Theme.of(context).colorScheme.surface,
          ),
          AsyncError() => const PasscodeLockScreen(
            key: Key('app_lock_error_fallback'),
            isBiometricEnabled: false,
          ),
        },
      ],
    );
  }
}
