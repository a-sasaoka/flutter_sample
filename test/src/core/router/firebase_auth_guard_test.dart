import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/core/router/firebase_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

class MockUser extends Mock implements User {}

void main() {
  late MockGoRouterState mockState;

  setUp(() {
    mockState = MockGoRouterState();
    when(() => mockState.uri).thenReturn(Uri.parse('/'));
  });

  String? executeGuard(User? user, {String location = '/'}) {
    when(() => mockState.uri).thenReturn(Uri.parse(location));

    final container = ProviderContainer(
      overrides: [
        // firebaseAuthStateProvider を指定した User オブジェクトで上書き
        firebaseAuthStateProvider.overrideWithValue(user),
      ],
    );
    addTearDown(container.dispose);

    return firebaseAuthGuard(container.read(Provider((ref) => ref)), mockState);
  }

  group('firebaseAuthGuard テスト', () {
    test('ログイン済みかつメール未認証の場合、メール認証画面へリダイレクトすること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(false);

      final result = executeGuard(mockUser);

      expect(result, const EmailVerificationRoute().location);
    });

    test('ログイン済みかつメール未認証だが、すでにメール認証画面にいる場合はリダイレクトしないこと', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(false);

      final result = executeGuard(
        mockUser,
        location: const EmailVerificationRoute().location,
      );

      // AuthGuardHelper.redirect に判定が移る（この場合は null が期待される）
      expect(result, isNull);
    });

    test('ログイン済みかつメール認証済みの場合、AuthGuardHelper に判定が委譲されること', () {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);

      // ログイン済みでログイン画面にいる場合
      final result = executeGuard(
        mockUser,
        location: const LoginRoute().location,
      );

      // AuthGuardHelper によりホームへリダイレクトされることを確認
      expect(result, const HomeRoute().location);
    });

    test('未ログインの場合、AuthGuardHelper に判定が委譲されること', () {
      // ユーザーが null (未ログイン)
      final result = executeGuard(null);

      // AuthGuardHelper によりログイン画面へリダイレクトされることを確認
      expect(result, const LoginRoute().location);
    });
  });
}
