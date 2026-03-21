import 'dart:async';

import 'package:flutter/foundation.dart'; // SynchronousFuture 用
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/core/router/auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

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

void main() {
  late MockGoRouterState mockState;

  setUp(() {
    mockState = MockGoRouterState();
    when(() => mockState.matchedLocation).thenReturn('/');
    when(() => mockState.uri).thenReturn(Uri.parse('/'));
  });

  String? executeGuard(AsyncValue<bool> authState, {String location = '/'}) {
    when(() => mockState.matchedLocation).thenReturn(location);
    when(() => mockState.uri).thenReturn(Uri.parse(location));

    final container = ProviderContainer(
      overrides: [
        // 💡 修正ポイント: 引数なしの overrideWith
        authStateProvider.overrideWith(
          () => _FakeAuthStateNotifier(authState),
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
      expect(result, const SplashRoute().location);
    });

    test('ログイン済み（Data: true）の場合、ログイン画面からホームへリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        location: const LoginRoute().location,
      );
      expect(result, const HomeRoute().location);
    });

    test('ログイン済み（Data: true）で、すでにホームにいる場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(true),
        location: const HomeRoute().location,
      );
      expect(result, isNull);
    });

    test('未ログイン（Data: false）の場合、ホームからログイン画面にリダイレクトすること', () {
      final result = executeGuard(
        const AsyncData<bool>(false),
        location: const HomeRoute().location,
      );
      expect(result, const LoginRoute().location);
    });

    test('未ログイン（Data: false）で、すでにログイン画面にいる場合、リダイレクトしないこと', () {
      final result = executeGuard(
        const AsyncData<bool>(false),
        location: const LoginRoute().location,
      );
      expect(result, isNull);
    });

    test('認証状態でエラーが発生した場合、未ログイン扱いとしてログイン画面にリダイレクトすること', () {
      final result = executeGuard(
        AsyncValue<bool>.error(Exception('Auth Error'), StackTrace.empty),
        location: const HomeRoute().location,
      );
      expect(result, const LoginRoute().location);
    });
  });
}
