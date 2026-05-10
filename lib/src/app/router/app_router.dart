import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/auth_guard.dart';
import 'package:flutter_sample/src/app/router/firebase_auth_guard.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/analytics/typed_route_analytics_observer.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_sign_up_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_display_screen.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_input_screen.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_screen.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 🏠 ホーム画面ルート
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<UserListRoute>(path: 'users'),
    TypedGoRoute<ResetPasswordRoute>(path: 'reset-password'),
    TypedGoRoute<ChatRoute>(path: 'chat'),
    TypedGoRoute<MemosRoute>(path: 'memos'),
    TypedGoRoute<ChartInputRoute>(
      path: 'chart-input',
      routes: [
        TypedGoRoute<ChartDisplayRoute>(path: 'display'),
      ],
    ),
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

/// 📊 グラフ入力画面ルート
class ChartInputRoute extends GoRouteData with $ChartInputRoute {
  /// コンストラクタ
  const ChartInputRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChartInputScreen();
  }
}

/// 📈 グラフ表示画面ルート
class ChartDisplayRoute extends GoRouteData with $ChartDisplayRoute {
  /// コンストラクタ
  const ChartDisplayRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChartDisplayScreen();
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

/// 🔑 パスワードリセット画面ルート
class ResetPasswordRoute extends GoRouteData with $ResetPasswordRoute {
  /// コンストラクタ
  const ResetPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseResetPasswordScreen();
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

/// 📝 メモ一覧画面ルート
class MemosRoute extends GoRouteData with $MemosRoute {
  /// コンストラクタ
  const MemosRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MemoScreen();
  }
}

/// 🔐 ログイン画面ルート
@TypedGoRoute<LoginRoute>(
  path: '/login',
  routes: [
    TypedGoRoute<SignUpRoute>(path: 'signup'),
  ],
)
class LoginRoute extends GoRouteData with $LoginRoute {
  /// コンストラクタ
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return Consumer(
      builder: (context, ref, child) {
        // Firebase Authenticationの利用有無で遷移先画面を切り替える
        final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;
        if (useFirebase) {
          return const FirebaseLoginScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/// 🧾 サインアップ画面ルート
class SignUpRoute extends GoRouteData with $SignUpRoute {
  /// コンストラクタ
  const SignUpRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseSignUpScreen();
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

/// 🌐 GoRouterのインスタンスをRiverpodで提供
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;

  // 認証状態の変更を検知して GoRouter にルーティングの再評価を促すための Listenable
  final routerListenable = ValueNotifier<bool>(false);

  // 使用している認証方式のみを監視対象にする
  if (useFirebase) {
    ref.listen(
      firebaseAuthStateProvider,
      (_, _) => routerListenable.value = !routerListenable.value,
    );
  } else {
    ref.listen(
      authStateProvider,
      (_, _) => routerListenable.value = !routerListenable.value,
    );
  }

  ref.onDispose(routerListenable.dispose);

  return GoRouter(
    refreshListenable: routerListenable,
    routes: $appRoutes,
    redirect: (context, state) {
      // Firebase Authenticationの利用有無で認証ガードを切り替える
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
        analytics: ref.watch(firebaseAnalyticsProvider),
        talker: ref.watch(loggerProvider),
      ),
    ],
  );
}
