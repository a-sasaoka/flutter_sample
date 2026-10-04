import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/services/app_lock_state_provider.dart';
import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/data/app_lock_overrides.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StubAppLockService extends AppLockService {
  StubAppLockService(this._buildState);
  final Future<AppLockState> Function() _buildState;

  @override
  Future<AppLockState> build() => _buildState();

  @override
  Future<T> runWithLockSuppression<T>(Future<T> Function() action) => action();
}

class ErrorStubAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() {
    state = AsyncError(Exception('AppLock error'), StackTrace.empty);
    return Completer<AppLockState>().future;
  }

  @override
  Future<T> runWithLockSuppression<T>(Future<T> Function() action) => action();
}

void main() {
  group('getAppLockOverrides', () {
    test('オーバーライド設定が正しく適用され、AppLockServiceのハンドラーが実行されること', () async {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(
            () => StubAppLockService(() async => const AppLockState.disabled()),
          ),
          ...getAppLockOverrides().cast(),
        ],
      );
      addTearDown(container.dispose);

      final runner = container.read(lockSuppressionRunnerProvider);
      var executed = false;
      final result = await runner(() async {
        executed = true;
        return 'success';
      });

      check(executed).equals(true);
      check(result).equals('success');
    });

    test('isAppUnlockedProvider: Unlocked の場合は true を返すこと', () async {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(
            () => StubAppLockService(
              () async =>
                  const AppLockState.unlocked(isBiometricEnabled: false),
            ),
          ),
          ...getAppLockOverrides().cast(),
        ],
      );
      addTearDown(container.dispose);

      // 非同期初期化を待機
      await container.read(appLockServiceProvider.future);

      final isUnlocked = container.read(isAppUnlockedProvider);
      check(isUnlocked).equals(true);
    });

    test('isAppUnlockedProvider: Disabled の場合は true を返すこと', () async {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(
            () => StubAppLockService(() async => const AppLockState.disabled()),
          ),
          ...getAppLockOverrides().cast(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockServiceProvider.future);

      final isUnlocked = container.read(isAppUnlockedProvider);
      check(isUnlocked).equals(true);
    });

    test('isAppUnlockedProvider: Locked の場合は false を返すこと', () async {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(
            () => StubAppLockService(
              () async => const AppLockState.locked(isBiometricEnabled: false),
            ),
          ),
          ...getAppLockOverrides().cast(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appLockServiceProvider.future);

      final isUnlocked = container.read(isAppUnlockedProvider);
      check(isUnlocked).equals(false);
    });

    test('isAppUnlockedProvider: ローディング中は false を返すこと', () {
      final completer = Completer<AppLockState>();
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(
            () => StubAppLockService(() => completer.future),
          ),
          ...getAppLockOverrides().cast(),
        ],
      );
      addTearDown(container.dispose);

      // 初期化未完了の段階（AsyncLoading）で確認
      final isUnlocked = container.read(isAppUnlockedProvider);
      check(isUnlocked).equals(false);
    });

    test('isAppUnlockedProvider: エラー時は false を返すこと', () {
      final container = ProviderContainer(
        overrides: [
          appLockServiceProvider.overrideWith(ErrorStubAppLockService.new),
          ...getAppLockOverrides().cast(),
        ],
      );
      addTearDown(container.dispose);

      final isUnlocked = container.read(isAppUnlockedProvider);
      check(isUnlocked).equals(false);
    });
  });
}
