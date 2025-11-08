// lib/src/core/widgets/settings_screen.dart
// テーマモードの切り替えUI（ドロップダウン + ダークモードの簡易スイッチ）

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 設定画面ウィジェット
class SettingsScreen extends ConsumerWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: theme.when(
        data: (mode) {
          final notifier = ref.read(themeModeProvider.notifier);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('🎨 テーマ設定'),
              const SizedBox(height: 8),
              DropdownButton<ThemeMode>(
                value: mode,
                onChanged: (v) async {
                  if (v != null) await notifier.set(v);
                },
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System（端末に合わせる）'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light（明るい）'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark（暗い）'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('ダークモードに切り替える（簡易）'),
                value: mode == ThemeMode.dark,
                onChanged: (_) => notifier.toggleLightDark(),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
