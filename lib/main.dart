// MaterialApp.router に GoRouter を渡すのがポイントです。
// Riverpod を使うために最上位に ProviderScope を置きます。
// theme/darkTheme/themeMode を追加します。

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // ここで GoRouter とテーマを取得
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return themeMode.when(
      data: (mode) => MaterialApp.router(
        title: 'Flutter Sample',
        theme: AppTheme.light(), // ライト
        darkTheme: AppTheme.dark(), // ダーク
        themeMode: mode, // 現在のモード
        routerConfig: router, // ← これが GoRouter の本体
        debugShowCheckedModeBanner: false,
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
