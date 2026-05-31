import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/firebase_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

class MockUser extends Mock implements User {}

// --- SplashStateのフェイク定義 ---
class FakeSplashState extends SplashState {
  FakeSplashState({required this.initialValue});
  final bool initialValue;

  @override
  bool build() => initialValue;
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
  }) {
    when(() => mockState.uri).thenReturn(Uri.parse(location));

    final container = ProviderContainer(
      overrides: [
        // firebaseAuthStateProvider に authState (AsyncValue<User?>) を直接上書き
        firebaseAuthStateProvider.overrideWithValue(authState),
        splashStateProvider.overrideWith(
          () => FakeSplashState(initialValue: isSplashFinished),
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

    test('スプラッシュ未完了の場合、常に SplashRoute にリダイレクトすること', () {
      final mockUser = MockUser();
      final result = executeGuard(
        AsyncData(mockUser),
        isSplashFinished: false,
      );
      check(result).equals(const SplashRoute().location);
    });

    test('スプラッシュ完了後、スプラッシュ画面にいてログイン済みの場合、ホーム画面へリダイレクトすること', () {
      final mockUser = MockUser();
      final result = executeGuard(
        AsyncData(mockUser),
        location: const SplashRoute().location,
      );
      check(result).equals(const HomeRoute().location);
    });

    test('スプラッシュ完了後、スプラッシュ画面にいて未ログインの場合、ログイン画面へリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData(null),
        location: const SplashRoute().location,
      );
      check(result).equals(const LoginRoute().location);
    });
  });
}
