// lib/src/core/widgets/home_screen.dart
// ホーム画面。各ページへの遷移ボタンを置きます。

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// ホーム画面のウィジェット
class HomeScreen extends StatelessWidget {
  /// コンストラクタ
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初心者向けメモ：
    // - XXXRoute().go(context) で遷移すると履歴を置き換えになります（戻るボタンで戻れない）
    // - XXXRoute().push<void>(context) ならスタックに積む遷移です（戻るボタンで戻れる）
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('👋 ここはホーム画面です。下のボタンから各画面へ移動してみましょう。'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => const SettingsRoute().push<void>(context),
            child: const Text('設定画面へ（/settings）'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => const SampleRoute().push<void>(context),
            child: const Text('サンプル画面へ（/sample）'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/undefined/path'),
            child: const Text('存在しないパスに遷移（NotFoundの動作確認）'),
          ),
        ],
      ),
    );
  }
}
