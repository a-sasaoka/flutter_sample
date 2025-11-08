// lib/src/core/widgets/settings_screen.dart
// 設定画面のシンプルな雛形。

import 'package:flutter/material.dart';

/// SettingsScreen ウィジェット
class SettingsScreen extends StatelessWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('ここに設定項目を追加していきます。'),
      ),
    );
  }
}
