// lib/main.dart
// MaterialApp.router に GoRouter を渡すのがポイントです。
// Riverpod を使うために最上位に ProviderScope を置きます。

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// アプリ本体のウィジェット
class MyApp extends ConsumerWidget {
  /// コンストラクタ
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ここで GoRouter を取得
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Flutter Sample',
      // 今後 flex_color_scheme のテーマをここに適用予定
      routerConfig: router, // ← これが GoRouter の本体
      debugShowCheckedModeBanner: false,
    );
  }
}
