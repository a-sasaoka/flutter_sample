import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/auth_guard.dart';
import 'package:flutter_sample/src/app/router/firebase_auth_guard.dart';
import 'package:flutter_sample/src/app/router/main_shell_screen.dart';
import 'package:flutter_sample/src/app/router/snackbar_navigation_observer.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/analytics/typed_route_analytics_observer.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/scaffold_messenger_key.dart';
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
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';
part 'routes/auth_routes.dart';
part 'routes/chat_tab_routes.dart';
part 'routes/chart_tab_routes.dart';
part 'routes/home_tab_routes.dart';
part 'routes/memos_tab_routes.dart';
part 'routes/shell_routes.dart';
part 'routes/onboarding_routes.dart';
part 'routes/splash_routes.dart';
part 'routes/user_tab_routes.dart';

/// 🌐 GoRouterのインスタンスをRiverpodで提供
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;

  // 認証状態の変更を検知して GoRouter にルーティングの再評価を促すための Listenable
  final routerListenable = ValueNotifier<bool>(false);

  // スプラッシュ画面の表示が完了したときも、画面遷移を再評価する
  ref
    ..listen(
      splashStateProvider,
      (_, _) => routerListenable.value = !routerListenable.value,
    )
    // オンボーディング完了状態が更新されたときも、画面遷移を再評価する
    ..listen(
      onboardingProvider,
      (_, _) => routerListenable.value = !routerListenable.value,
    );

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
      SnackBarNavigationObserver(scaffoldMessengerKey),
      TypedRouteAnalyticsObserver(
        analytics: ref.watch(firebaseAnalyticsProvider),
        talker: ref.watch(loggerProvider),
      ),
    ],
  );
}
