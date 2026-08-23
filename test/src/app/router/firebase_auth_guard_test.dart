import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/firebase_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

class MockUser extends Mock implements User {}

class _FakeNotificationNotifierWithPayload extends NotificationNotifier {
  _FakeNotificationNotifierWithPayload(this.initialPayload);
  final NotificationPayload initialPayload;
  bool _consumed = false;

  @override
  NotificationState build() {
    return NotificationState.data(
      initialPayload: _consumed ? null : initialPayload,
    );
  }

  @override
  NotificationPayload? consumeInitialPayload() {
    if (_consumed) return null;
    _consumed = true;
    return initialPayload;
  }
}

class _FakeNotificationNotifierWithState extends NotificationNotifier {
  _FakeNotificationNotifierWithState(this.initialState);
  final NotificationState initialState;
  bool _consumed = false;

  @override
  NotificationState build() {
    if (_consumed && initialState is NotificationStateData) {
      return (initialState as NotificationStateData).copyWith(
        initialPayload: null,
      );
    }
    return initialState;
  }

  @override
  NotificationPayload? consumeInitialPayload() {
    if (_consumed) return null;
    _consumed = true;
    if (initialState case final NotificationStateData data) {
      return data.initialPayload;
    }
    return null;
  }
}

// --- SplashStateのフェイク定義 ---
class FakeSplashState extends SplashState {
  FakeSplashState({required this.initialValue});
  final bool initialValue;

  @override
  bool build() => initialValue;
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
    when(() => mockState.uri).thenReturn(Uri.parse('/'));
  });

  String? executeGuard(
    AsyncValue<User?> authState, {
    String location = '/',
    bool isSplashFinished = true,
    bool isOnboardingCompleted = true,
    bool isOnboardingLoading = false,
    bool isOnboardingError = false,
    NotificationPayload? initialPayload,
    NotificationState? notificationState,
  }) {
    when(() => mockState.matchedLocation).thenReturn(location);
    when(() => mockState.uri).thenReturn(Uri.parse(location));

    final container = ProviderContainer(
      overrides: [
        // firebaseAuthStateProvider に authState (AsyncValue<User?>) を直接上書き
        firebaseAuthStateProvider.overrideWithValue(authState),
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
        if (notificationState != null)
          notificationProvider.overrideWith(
            () => _FakeNotificationNotifierWithState(notificationState),
          )
        else if (initialPayload != null)
          notificationProvider.overrideWith(
            () => _FakeNotificationNotifierWithPayload(initialPayload),
          )
        else
          notificationProvider.overrideWith(
            () => _FakeNotificationNotifierWithState(
              const NotificationState.data(),
            ),
          ),
      ],
    );
    addTearDown(container.dispose);

    return firebaseAuthGuard(container.read(Provider((ref) => ref)), mockState);
  }

  group('firebaseAuthGuard テスト', () {
    test('ログイン確認中（ローディング中）の場合、SplashRoute にリダイレクトすること', () {
      final result = executeGuard(const AsyncLoading<User?>());

      check(result).equals(const SplashRoute().location);
    });

    test('ログイン済みかつメール未認証の場合、メール認証画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(false);

      final result = executeGuard(AsyncData(mockUser));

      check(result).equals(const EmailVerificationRoute().location);
    });

    test('ログイン済みかつメール未認証だが、すでにメール認証画面にいる場合はリダイレクトしないこと', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(false);

      final result = executeGuard(
        AsyncData(mockUser),
        location: const EmailVerificationRoute().location,
      );

      // AuthGuardHelper.redirect に判定が移る（この場合は null が期待される）
      check(result).isNull();
    });

    test('ログイン済みかつメール認証済みの場合、AuthGuardHelper に判定が委譲されること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);

      // ログイン済みでログイン画面にいる場合
      final result = executeGuard(
        AsyncData(mockUser),
        location: const LoginRoute().location,
      );

      // AuthGuardHelper によりホームへリダイレクトされることを確認
      check(result).equals(const HomeRoute().location);
    });

    test('未ログインの場合、AuthGuardHelper に判定が委譲されること', () {
      // ユーザーが null (未ログイン)
      final result = executeGuard(const AsyncData(null));

      // AuthGuardHelper によりログイン画面へリダイレクトされることを確認（fromパラメータ付き）
      check(result).isNotNull().startsWith(const LoginRoute().location);
      check(result).isNotNull().contains('from=${Uri.encodeComponent('/')}');
    });

    test('スプラッシュ未完了の場合、SplashRoute にリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isSplashFinished: false,
      );
      check(result).equals(const SplashRoute().location);
    });

    test('スプラッシュ完了後、スプラッシュ画面にいてログイン済みの場合、ホーム画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        location: const SplashRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });

    test('ログイン済みで通知状態がローディング中の場合、スプラッシュを維持すること（nullを返す）', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        location: const SplashRoute().location,
        notificationState: const NotificationState.loading(),
      );
      check(result).isNull();
    });

    test('ログイン済みでスプラッシュ画面に初期通知（initialPayload）が存在する場合、通知パスへリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      const payload = NotificationPayload(
        path: '/chat',
        title: 'Initial Chat',
      );
      final result = executeGuard(
        AsyncData(mockUser),
        location: const SplashRoute().location,
        initialPayload: payload,
      );
      check(result).equals('/chat');
    });

    test('スプラッシュ完了後、スプラッシュ画面にいて未ログインの場合、ログイン画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData(null),
        location: const SplashRoute().location,
      );
      check(result).equals(const LoginRoute().location);
    });

    test('オンボーディングが未完了の場合、オンボーディング画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isOnboardingCompleted: false,
        location: const HomeRoute().location,
      );
      check(result).equals(const OnboardingRoute().location);
    });

    test('すでにオンボーディング画面にいてオンボーディング未完了の場合、リダイレクトしないこと', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isOnboardingCompleted: false,
        location: const OnboardingRoute().location,
      );
      check(result).isNull();
    });

    test('オンボーディング状態がローディング中の場合、SplashRouteにリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isOnboardingLoading: true,
        location: const HomeRoute().location,
      );
      check(result).equals(const SplashRoute().location);
    });

    test('オンボーディング完了済みで、ログイン済みかつオンボーディング画面にいる場合、ホーム画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        location: const OnboardingRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });

    test('オンボーディング完了済みで、未ログインかつオンボーディング画面にいる場合、ログイン画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData(null),
        location: const OnboardingRoute().location,
      );
      check(result).isNotNull().startsWith(const LoginRoute().location);
    });

    test('オンボーディング状態がローディング中で、すでにオンボーディング画面にいる場合、リダイレクトしないこと', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isOnboardingLoading: true,
        location: const OnboardingRoute().location,
      );
      check(result).isNull();
    });

    test('オンボーディング状態がエラーの場合、オンボーディング画面以外からオンボーディング画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isOnboardingError: true,
        location: const HomeRoute().location,
      );
      check(result).equals(const OnboardingRoute().location);
    });

    test('オンボーディング状態がエラーで、すでにオンボーディング画面にいる場合、リダイレクトしないこと', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        isOnboardingError: true,
        location: const OnboardingRoute().location,
      );
      check(result).isNull();
    });

    test('ログイン済みかつメール認証が完了した状態でメール認証画面にアクセスした場合、ホーム画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      final result = executeGuard(
        AsyncData(mockUser),
        location: const EmailVerificationRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });
  });
}
