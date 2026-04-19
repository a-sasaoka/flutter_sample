// Riverpod + GoRouter + アノテーション対応版
// GoRouterBuilderによる型安全なルーティング + riverpod_generator対応

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:flutter_sample/src/core/router/auth_guard.dart';
import 'package:flutter_sample/src/core/router/firebase_auth_guard.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_sign_up_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_sample/src/features/sample_feature/presentation/sample_screen.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 🏠 ホーム画面ルート
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<SampleRoute>(path: 'sample'),
    TypedGoRoute<UserListRoute>(path: 'users'),
    TypedGoRoute<ChatRoute>(path: 'chat'),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  /// コンストラクタ
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

/// ⚙️ 設定画面ルート
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// コンストラクタ
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

/// 🧪 サンプル画面ルート
class SampleRoute extends GoRouteData with $SampleRoute {
  /// コンストラクタ
  const SampleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SampleScreen();
  }
}

/// 👥 ユーザー一覧画面ルート
class UserListRoute extends GoRouteData with $UserListRoute {
  /// コンストラクタ
  const UserListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserListScreen();
  }
}

/// 🔐 ログイン画面ルート
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  /// コンストラクタ
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context);
    final useFirebase = container.read(useFirebaseAuthProvider);

    if (useFirebase) {
      return const FirebaseLoginScreen();
    }
    return const LoginScreen();
  }
}

/// スプラッシュ画面ルート
@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  /// コンストラクタ
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashScreen();
  }
}

/// 🧾 サインアップ画面ルート
@TypedGoRoute<SignUpRoute>(path: '/signup')
class SignUpRoute extends GoRouteData with $SignUpRoute {
  /// コンストラクタ
  const SignUpRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseSignUpScreen();
  }
}

/// 🔑 パスワードリセット画面ルート
@TypedGoRoute<ResetPasswordRoute>(path: '/reset-password')
class ResetPasswordRoute extends GoRouteData with $ResetPasswordRoute {
  /// コンストラクタ
  const ResetPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseResetPasswordScreen();
  }
}

/// 📧 メールアドレス確認画面ルート
@TypedGoRoute<EmailVerificationRoute>(path: '/email-verification')
class EmailVerificationRoute extends GoRouteData with $EmailVerificationRoute {
  /// コンストラクタ
  const EmailVerificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseEmailVerificationScreen();
  }
}

/// 🤖 AIチャット画面ルート
class ChatRoute extends GoRouteData with $ChatRoute {
  /// コンストラクタ
  const ChatRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChatScreen();
  }
}

/// Firebase Analytics の screen_class をカスタマイズして送信するカスタム Observer
class TypedRouteAnalyticsObserver extends NavigatorObserver {
  /// コンストラクタ
  TypedRouteAnalyticsObserver({required this.ref, required this.analytics});

  /// Firebase Analytics インスタンス
  final FirebaseAnalytics analytics;

  /// Ref
  final Ref ref;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sendScreenView(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _sendScreenView(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _sendScreenView(Route<dynamic> route) {
    final settings = route.settings;
    final runtimeTypeName = settings.name ?? route.runtimeType.toString();

    final screenClass = runtimeTypeName.replaceAll(r'$', '');

    unawaited(
      analytics.logScreenView(
        screenClass: screenClass,
        screenName: screenClass,
      ),
    );

    // ProviderContainer自体が有効か、Refが有効かを確認して実行
    if (ref.mounted) {
      try {
        ref.read(loggerProvider).d('📊 screen_view → $screenClass');
      } on Exception catch (_) {
        // 消滅済みの場合はログ出力自体をスキップ
      }
    }
  }
}

/// 🌐 GoRouterのインスタンスをRiverpodで提供
@riverpod
GoRouter router(Ref ref) {
  final useFirebase = ref.watch(useFirebaseAuthProvider);

  return GoRouter(
    routes: $appRoutes,
    redirect: (context, state) {
      if (useFirebase) {
        return firebaseAuthGuard(ref, state);
      }
      return authGuard(ref, state);
    },
    errorBuilder: (context, state) =>
        NotFoundScreen(unknownPath: state.uri.toString()),
    debugLogDiagnostics: true,
    observers: [
      TypedRouteAnalyticsObserver(
        ref: ref,
        analytics: ref.read(firebaseAnalyticsProvider),
      ),
    ],
  );
}
