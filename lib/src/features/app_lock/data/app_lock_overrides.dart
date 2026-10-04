import 'package:flutter_sample/src/core/services/app_lock_state_provider.dart';
import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// アプリロック関連のプロバイダーオーバーライド一覧を取得します。
List<dynamic> getAppLockOverrides() {
  return [
    lockSuppressionRunnerProvider.overrideWith(
      (ref) =>
          ref.watch(appLockServiceProvider.notifier).runWithLockSuppression,
    ),
    isAppUnlockedProvider.overrideWith((ref) {
      final appLockAsync = ref.watch(appLockServiceProvider);
      return switch (appLockAsync) {
        AsyncData(:final value) => switch (value) {
          AppLockStateUnlocked() || AppLockStateDisabled() => true,
          _ => false,
        },
        _ => false,
      };
    }),
  ];
}
