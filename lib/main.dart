import 'dart:async';
import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/firebase_options.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flavorを取得（文字列で扱うとエラーの原因になるので、enumに変換する）
  final flavor = Flavor.fromString(AppEnv.flavor);
  final isProd = flavor == Flavor.prod;

  // アプリのパッケージ情報を取得
  final packageInfo = await PackageInfo.fromPlatform();

  // Firebaseの初期化（DefaultFirebaseOptionsは環境別の内容を読み込む）
  await Firebase.initializeApp(options: firebaseOptionsWithFlavor(flavor));

  // デバッグ用のトークン
  final myDebugToken = AppEnv.debugToken;

  // App Checkの有効化（デバッグモード）
  await FirebaseAppCheck.instance.activate(
    // Androidのエミュレータ/実機用のデバッグプロバイダ
    providerAndroid: AndroidDebugProvider(debugToken: myDebugToken),
    // iOSのシミュレータ/実機用のデバッグプロバイダ
    providerApple: AppleDebugProvider(debugToken: myDebugToken),
  );

  // コンテナ生成の前に Talker を初期化
  final talker = TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: !isProd,
      useHistory: !isProd,
    ),
    observer: CustomTalkerObserver(
      isProd: isProd,
      recordError: (error, stack, {required fatal}) async {
        // CustomTalkerObserver 側で指定された fatal フラグ (false) をそのまま渡す
        await FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: fatal,
        );
      },
    ),
  );

  final container = ProviderContainer(
    overrides: [
      // プロバイダーにFlavorを設定
      flavorProvider.overrideWithValue(flavor),

      // プロバイダーにPackageInfoを設定
      packageInfoProvider.overrideWithValue(packageInfo),

      // プロバイダーにTokenRefreshCallbackを設定
      tokenRefreshCallbackProvider.overrideWith(
        (ref) => ref.watch(authRepositoryProvider).refreshToken,
      ),

      // プロバイダーにTalkerを設定
      loggerProvider.overrideWithValue(talker),
    ],
    observers: [
      // ObserverにもTalkerを設定
      TalkerRiverpodObserver(talker: talker),
    ],
  );

  // Flutterフレームワークのエラー
  FlutterError.onError = (details) {
    talker.error('Flutter Error', details.exception, details.stack);
    unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
  };

  // Dartの未処理例外
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.error('Uncaught Exception', error, stack);
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };

  // コンテナからアナリティクスを読み込んで送信
  final analytics = container.read(analyticsServiceProvider);
  await analytics.logEvent(
    event: AnalyticsEvent.appStarted,
    parameters: {'env': flavor.name},
  );

  // コンテナは破棄 (dispose) せず、そのままアプリに渡す
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

/// アプリ本体のウィジェット
class MyApp extends ConsumerWidget {
  /// コンストラクタ
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // アプリ全体の設定をまとめて取得
    final configAsync = ref.watch(appConfigProvider);

    return configAsync.when(
      data: (tuple) {
        return MaterialApp.router(
          locale: tuple.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          title: '',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: tuple.theme,
          routerConfig: tuple.router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => _AppTitleWrapper(child: child),
        );
      },
      loading: () => const Directionality(
        // MaterialAppやMaterialApp.routerを使わない
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Colors.white,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => Directionality(
        // MaterialAppやMaterialApp.routerを使わない
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Colors.white,
          child: Center(
            child: Text(
              'Fatal Error / A fatal error has occurred.\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

/// アプリのタイトルや共通設定をラップするウィジェット
class _AppTitleWrapper extends StatelessWidget {
  const _AppTitleWrapper({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null || child == null) {
      return child ?? const SizedBox.shrink();
    }

    return Title(
      title: l10n.appTitle,
      color: Theme.of(context).colorScheme.surface,
      child: child!,
    );
  }
}
