// MaterialApp.router に GoRouter を渡すのがポイントです。
// Riverpod を使うために最上位に ProviderScope を置きます。
// theme/darkTheme/themeMode を追加します。

import 'dart:async';
import 'dart:ui';

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
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flavorを取得（文字列で扱うとエラーの原因になるので、enumに変換する）
  final flavor = Flavor.values.byName(AppEnv.flavor);

  // Firebaseの初期化（DefaultFirebaseOptionsは環境別の内容を読み込む）
  await Firebase.initializeApp(options: firebaseOptionsWithFlavor(flavor));

  // Crashlytics: Flutterエラーを記録
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: Dartの未処理例外を記録
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };

  final container = ProviderContainer();
  final analytics = container.read(analyticsServiceProvider);

  await analytics.logEvent(
    event: AnalyticsEvent.appStarted,
    parameters: {
      'env': const String.fromEnvironment(
        'FLUTTER_ENV',
        defaultValue: 'unknown',
      ),
    },
  );
  container.dispose();

  runApp(
    ProviderScope(
      overrides: [
        // プロバイダーにFlavorを設定
        flavorProvider.overrideWithValue(flavor),
      ],
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
        final router = tuple.router;
        final themeMode = tuple.theme;
        final locale = tuple.locale;

        return MaterialApp.router(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          title: '', // temporary placeholder
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final l10n = AppLocalizations.of(context);
            if (l10n == null) {
              return const SizedBox.shrink();
            }
            return Title(
              title: l10n.appTitle,
              color: Theme.of(context).colorScheme.surface,
              child: MediaQuery(
                data: MediaQuery.of(context),
                child: child!,
              ),
            );
          },
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) {
        final l10n = AppLocalizations.of(context)!;
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('${l10n.errorOccurred}: $err'),
            ),
          ),
        );
      },
    );
  }
}
