// MaterialApp.router に GoRouter を渡すのがポイントです。
// Riverpod を使うために最上位に ProviderScope を置きます。
// theme/darkTheme/themeMode を追加します。

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/firebase_options.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
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
    final l10n = AppLocalizations.of(context)!;

    return configAsync.when(
      data: (tuple) {
        final router = tuple.router;
        final themeMode = tuple.theme;
        final locale = tuple.locale;

        return MaterialApp.router(
          title: l10n.appTitle,
          theme: AppTheme.light(), // ライト
          darkTheme: AppTheme.dark(), // ダーク
          themeMode: themeMode, // 現在のモード
          routerConfig: router, // ← これが GoRouter の本体
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('${l10n.errorOccurred}: $err'),
          ),
        ),
      ),
    );
  }
}
