import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/base_auth_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  late AuthGuardHelper helper;
  late MockGoRouterState mockState;

  setUp(() {
    helper = AuthGuardHelper(
      loginLocation: const LoginRoute().location,
      defaultLocation: const HomeRoute().location,
      guestOnlyPaths: {
        const LoginRoute().location,
        const SignUpRoute().location,
      },
      alwaysPublicPaths: {
        const SplashRoute().location,
      },
    );
    mockState = MockGoRouterState();
  });

  // state.uri を設定するためのユーティリティ
  void setLocation(String path) {
    when(() => mockState.uri).thenReturn(Uri.parse(path));
  }

  group('AuthGuardHelper.redirect', () {
    test('未ログインで非公開画面（ホーム）に行こうとした場合、fromパラメータ付きでログイン画面にリダイレクトすること', () {
      // Arrange
      const destination = '/'; // HomeRoute().location
      setLocation(destination);

      // Act
      final result = helper.redirect(isLoggedIn: false, state: mockState);

      // Assert
      // '/login?from=%2F' のような形式になるはず
      expect(result, contains(const LoginRoute().location));
      expect(result, contains('from=${Uri.encodeComponent(destination)}'));
    });

    test('未ログインでもゲスト専用画面（サインアップ）に行こうとした場合、リダイレクトしないこと', () {
      // Arrange
      setLocation(const SignUpRoute().location);

      // Act
      final result = helper.redirect(isLoggedIn: false, state: mockState);

      // Assert
      expect(result, isNull);
    });

    test('未ログインでも常に公開されている画面（スプラッシュ）に行こうとした場合、リダイレクトしないこと', () {
      // Arrange
      setLocation(const SplashRoute().location);

      // Act
      final result = helper.redirect(isLoggedIn: false, state: mockState);

      // Assert
      expect(result, isNull);
    });

    test('ログイン済みでゲスト専用画面（ログイン画面）に行こうとした場合、ホームにリダイレクトすること', () {
      // Arrange
      setLocation(const LoginRoute().location);

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, const HomeRoute().location);
    });

    test('ログイン済みかつfromパラメータがある状態でゲスト専用画面に行こうとした場合、fromの場所へリダイレクトすること', () {
      // Arrange
      const fromPath = '/settings';
      setLocation('${const LoginRoute().location}?from=$fromPath');

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, fromPath);
    });

    test('ログイン済みで認証必須画面（ホーム）に行く場合、リダイレクトしないこと', () {
      // Arrange
      setLocation(const HomeRoute().location);

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, isNull);
    });

    test('ログイン済みで常に公開されている画面（スプラッシュ）に行く場合、リダイレクトしないこと', () {
      // Arrange
      setLocation(const SplashRoute().location);

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, isNull);
    });
  });
}
