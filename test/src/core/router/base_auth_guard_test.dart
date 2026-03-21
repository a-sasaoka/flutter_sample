import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/core/router/base_auth_guard.dart'; // クラスが定義されているファイル名に合わせてください
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  late AuthGuardHelper helper;
  late MockGoRouterState mockState;

  setUp(() {
    helper = const AuthGuardHelper();
    mockState = MockGoRouterState();
  });

  // state.uri を設定するためのユーティリティ
  void setLocation(String path) {
    when(() => mockState.uri).thenReturn(Uri.parse(path));
  }

  group('AuthGuardHelper.redirect', () {
    test('未ログインで非公開画面（ホーム）に行こうとした場合、ログイン画面にリダイレクトすること', () {
      // Arrange
      setLocation(const HomeRoute().location); // '/'

      // Act
      final result = helper.redirect(isLoggedIn: false, state: mockState);

      // Assert
      expect(result, const LoginRoute().location); // '/login'
    });

    test('未ログインでも公開画面（サインアップ）に行こうとした場合、リダイレクトしないこと', () {
      // Arrange
      setLocation(const SignUpRoute().location); // '/signup'

      // Act
      final result = helper.redirect(isLoggedIn: false, state: mockState);

      // Assert
      expect(result, isNull);
    });

    test('ログイン済みでログイン画面に行こうとした場合、ホームにリダイレクトすること', () {
      // Arrange
      setLocation(const LoginRoute().location); // '/login'

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, const HomeRoute().location); // '/'
    });

    test('ログイン済みで非公開画面（ホーム）に行く場合、リダイレクトしないこと', () {
      // Arrange
      setLocation(const HomeRoute().location); // '/'

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, isNull);
    });

    test('ログイン済みで公開画面（スプラッシュ）に行く場合、条件に合致しないためリダイレクトしないこと', () {
      // Arrange
      setLocation(const SplashRoute().location); // '/splash'

      // Act
      final result = helper.redirect(isLoggedIn: true, state: mockState);

      // Assert
      expect(result, isNull);
    });
  });
}
