import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart'; // SynchronousFuture 用
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

// --- SplashStateのフェイク定義 ---
class FakeSplashState extends SplashState {
  FakeSplashState({required this.initialValue});
  final bool initialValue;

  @override
  bool build() => initialValue;
}

// --- Notifierのモック定義 ---
class _FakeAuthStateNotifier extends AuthStateNotifier {
  _FakeAuthStateNotifier(this.authState);
  final AsyncValue<bool> authState;

  @override
  Future<bool> build() {
    // Future.error ではなく、自ら state にエラーを叩き込む
    // これにより、読み取った瞬間に AsyncError 状態であることが確定します
    return authState.when(
      data: SynchronousFuture<bool>.new,
      error: (error, stack) {
        // 💡 同期的にエラー状態をセット
        state = AsyncError<bool>(error, stack);
        // build自体はエラーを投げつつ完了させる
        return Future.error(error, stack);
      },
      loading: () => Completer<bool>().future,
    );
  }
}

class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier({
    required this.completed,
    this.isLoading = false,
    this.hasError = false,
  });
  final bool completed;
  final bool isLoading;
  final bool hasError;

  @override
  FutureOr<bool> build() {
    if (hasError) {
      state = AsyncError<bool>(Exception('Onboarding Error'), StackTrace.empty);
      return Future.error(Exception('Onboarding Error'), StackTrace.empty);
    }
    if (isLoading) {
      return Completer<bool>().future;
    }
    return completed;
  }

  @override
  Future<void> complete() async {
    state = const AsyncData(true);
  }
}

void main() {
  late MockGoRouterState mockState;

  setUp(() {
    mockState = MockGoRouterState();
    when(() => mockState.matchedLocation).thenReturn('/');
    when(() => mockState.uri).thenReturn(Uri.parse('/'));
  });

  String? executeGuard(
    AsyncValue<bool> authState, {
    String location = '/',
    bool isSplashFinished = true,
    bool isOnboardingCompleted = true,
    bool isOnboardingLoading = false,
    bool isOnboardingError = false,
  }) {
    when(() => mockState.matchedLocation).thenReturn(location);
    when(() => mockState.uri).thenReturn(Uri.parse(location));

    final container = ProviderContainer(
      overrides: [
        // 💡 修正ポイント: 引数なしの overrideWith
        authStateProvider.overrideWith(
          () => _FakeAuthStateNotifier(authState),
        ),
        splashStateProvider.overrideWith(
          () => FakeSplashState(initialValue: isSplashFinished),
        ),
        onboardingProvider.overrideWith(
          () => _FakeOnboardingNotifier(
            completed: isOnboardingCompleted,
            isLoading: isOnboardingLoading,
            hasError: isOnboardingError,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 💡 重要：read して直後にガードを実行する
    return container.read(Provider((ref) => authGuard(ref, mockState)));
  }

  group('authGuard の状態ハンドリングテスト', () {
    test('認証状態が Loading の場合、SplashRoute にリダイレクトすること', () {
      final result = executeGuard(const AsyncLoading<bool>());
      check(result).equals(const SplashRoute().location);
    });

    test('ログイン済み（Data: true）の場合、ログイン画面からホームへリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        location: const LoginRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });

    test('ログイン済み（Data: true）で、すでにホームにいる場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        location: const HomeRoute().location,
      );
      check(result).isNull();
    });

    test('未ログイン（Data: false）の場合、ホームからログイン画面にリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(false),
        location: const HomeRoute().location,
      );
      check(result).isNotNull().startsWith(const LoginRoute().location);
      check(result).isNotNull().contains('from=${Uri.encodeComponent('/')}');
    });

    test('未ログイン（Data: false）で、すでにログイン画面にいる場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(false),
        location: const LoginRoute().location,
      );
      check(result).isNull();
    });

    test('認証状態でエラーが発生した場合、未ログイン扱いとしてログイン画面にリダイレクトすること', () {
      final result = executeGuard(
        AsyncValue<bool>.error(Exception('Auth Error'), StackTrace.empty),
        location: const HomeRoute().location,
      );
      check(result).isNotNull().startsWith(const LoginRoute().location);
      check(result).isNotNull().contains('from=${Uri.encodeComponent('/')}');
    });

    test('スプラッシュ未完了の場合、常に SplashRoute にリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isSplashFinished: false,
      );
      check(result).equals(const SplashRoute().location);
    });

    test('スプラッシュ完了後、スプラッシュ画面にいて未ログインの場合、ログイン画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(false),
        location: const SplashRoute().location,
      );
      check(result).equals(const LoginRoute().location);
    });

    test('スプラッシュ完了後、スプラッシュ画面にいてログイン済みの場合、ホーム画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        location: const SplashRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });

    test('オンボーディングが未完了の場合、オンボーディング画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isOnboardingCompleted: false,
        location: const HomeRoute().location,
      );
      check(result).equals(const OnboardingRoute().location);
    });

    test('すでにオンボーディング画面にいてオンボーディング未完了の場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isOnboardingCompleted: false,
        location: const OnboardingRoute().location,
      );
      check(result).isNull();
    });

    test('オンボーディング状態がローディング中の場合、SplashRouteにリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isOnboardingLoading: true,
        location: const HomeRoute().location,
      );
      check(result).equals(const SplashRoute().location);
    });

    test('オンボーディング完了済みで、ログイン済みかつオンボーディング画面にいる場合、ホーム画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        location: const OnboardingRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });

    test('オンボーディング完了済みで、未ログインかつオンボーディング画面にいる場合、ログイン画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(false),
        location: const OnboardingRoute().location,
      );
      check(result).isNotNull().startsWith(const LoginRoute().location);
    });

    test('オンボーディング状態がローディング中で、すでにオンボーディング画面にいる場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isOnboardingLoading: true,
        location: const OnboardingRoute().location,
      );
      check(result).isNull();
    });

    test('オンボーディング状態がエラーの場合、オンボーディング画面以外からオンボーディング画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isOnboardingError: true,
        location: const HomeRoute().location,
      );
      check(result).equals(const OnboardingRoute().location);
    });

    test('オンボーディング状態がエラーで、すでにオンボーディング画面にいる場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        isOnboardingError: true,
        location: const OnboardingRoute().location,
      );
      check(result).isNull();
    });
  });
}
