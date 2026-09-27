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
import 'package:flutter_sample/src/features/chart/presentation/sales_chart_screen.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/developer_storage_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/image_cache_demo_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/lottie_demo_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/push_notification_demo_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/rebuild_demo_screen.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_sample/src/features/home_widget/application/home_widget_service.dart';
import 'package:flutter_sample/src/features/legal/domain/legal_document_type.dart';
import 'package:flutter_sample/src/features/legal/presentation/legal_document_screen.dart';
import 'package:flutter_sample/src/features/map/presentation/map_screen.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_screen.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_sample/src/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/qr_scanner_history_screen.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/qr_scanner_screen.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/share/presentation/share_demo_screen.dart';
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
part 'routes/legal_routes.dart';
part 'routes/memos_tab_routes.dart';
part 'routes/shell_routes.dart';
part 'routes/onboarding_routes.dart';
part 'routes/splash_routes.dart';
part 'routes/user_tab_routes.dart';
part 'routes/dev_tools_routes.dart';

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

  final router = GoRouter(
    refreshListenable: routerListenable,
    routes: $appRoutes,
    redirect: (context, state) {
      // 📱 ホーム画面ウィジェットや外部連携からのカスタムスキームURIをアプリ内正規ルートへリダイレクト
      final uri = state.uri;
      if (uri.hasScheme &&
          (uri.scheme == 'sampleapp' || uri.scheme.startsWith('flsample'))) {
        final host = uri.host;
        final path = uri.path;
        if (path.contains('create') ||
            uri.queryParameters['action'] == 'create') {
          return '/memos?action=create';
        }
        if (host == 'memos' || path.contains('memos')) {
          return '/memos';
        }
      }

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

  // 🔔 通知状態の更新（初期通知ディープリンク再評価および通知タップ時の画面遷移）を監視
  ref.listen(notificationProvider, (previous, next) {
    routerListenable.value = !routerListenable.value;

    if (next case final NotificationStateData nextData) {
      final latestPayload = nextData.latestPayload;
      if (latestPayload != null && latestPayload.isNavigable) {
        final path = latestPayload.path;
        if (path != null) {
          ref.read(notificationProvider.notifier).consumeLatestPayload();
          router.go(path);
        }
      }
    }
  });

  // 📱 ホーム画面ウィジェットのタップ起動（コールドスタート＆バックグラウンド復帰）を監視
  final homeWidget = ref.watch(homeWidgetServiceProvider);
  final talker = ref.watch(loggerProvider);
  Uri? pendingWidgetUri;

  void handleWidgetUri(Uri uri) {
    talker.info('📱 [HomeWidget] Widget clicked with URI: $uri');
    final path = uri.path;
    final host = uri.host;
    if (path.contains('create')) {
      router.go('/memos?action=create');
    } else if (host == 'memos' || path.startsWith('/memos')) {
      router.go('/memos');
    }
  }

  // 1. バックグラウンド復帰時のタップを購読
  final widgetSubscription = homeWidget.widgetClicked.listen((uri) {
    if (uri != null) {
      handleWidgetUri(uri);
    }
  });
  ref.onDispose(widgetSubscription.cancel);

  // 2. コールドスタート（完全終了からの起動）時のタップURIを取得
  unawaited(
    homeWidget.getInitiallyLaunchedUri().then((uri) {
      if (uri != null) {
        final isSplashFinished = ref.read(splashStateProvider);
        if (isSplashFinished) {
          handleWidgetUri(uri);
        } else {
          // スプラッシュ表示中は保留にしておく
          pendingWidgetUri = uri;
        }
      }
    }),
  );

  // 3. スプラッシュ画面の終了を検知して、保留していたメモ画面へ遷移
  ref.listen(splashStateProvider, (previous, isFinished) {
    if (isFinished && pendingWidgetUri != null) {
      final uri = pendingWidgetUri!;
      pendingWidgetUri = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleWidgetUri(uri);
      });
    }
  });

  return router;
}
