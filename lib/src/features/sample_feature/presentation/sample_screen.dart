// lib/src/features/sample_feature/presentation/sample_screen.dart
// 「機能（feature）」配下の画面サンプル。
// 後で Riverpod の Provider や API 通信をここに繋げていきます。

import 'package:flutter/material.dart';

/// SampleScreen ウィジェット
class SampleScreen extends StatelessWidget {
  /// コンストラクタ
  const SampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sample Feature')),
      body: const Center(
        child: Text('サンプル機能の画面です。ここにUIや状態管理を追加します。'),
      ),
    );
  }
}
