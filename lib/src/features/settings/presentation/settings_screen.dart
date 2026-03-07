// テーマモードの切り替えUI（ドロップダウン + ダークモードの簡易スイッチ）

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 設定画面ウィジェット
class SettingsScreen extends ConsumerWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // アプリ全体の設定をまとめて取得
    final configAsync = ref.watch(appConfigProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: configAsync.when(
        data: (tuple) {
          final themeModeNotifier = ref.read(themeModeProvider.notifier);
          final localeNotifier = ref.read(localeProvider.notifier);
          final mode = tuple.theme;
          final locale = tuple.locale;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.settingsThemeSection),
              const SizedBox(height: 8),
              DropdownButton<ThemeMode>(
                value: mode,
                onChanged: (v) async {
                  if (v != null) await themeModeNotifier.set(v);
                },
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(
                      l10n.settingsThemeSystem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(
                      l10n.settingsThemeLight,
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(
                      l10n.settingsThemeDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.settingsThemeToggle),
                value: mode == ThemeMode.dark,
                onChanged: (_) => themeModeNotifier.toggleLightDark(),
              ),
              const SizedBox(height: 32),
              Text(l10n.settingsLocaleSection),
              DropdownButton<String>(
                value: locale?.languageCode,
                onChanged: (v) async {
                  await localeNotifier.setLocale(v);
                },
                items: [
                  DropdownMenuItem(
                    child: Text(
                      l10n.settingsLocaleSystem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ja',
                    child: Text(l10n.settingsLocaleJa),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(l10n.settingsLocaleEn),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.hello),
              if (AppEnv.useFirebaseAuth) ...[
                const SizedBox(height: 32),
                // 🚪 ログアウト（SignOut）ボタン
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(firebaseAuthRepositoryProvider.notifier)
                          .signOut();

                      // --- ログアウト成功 → ログイン画面へ遷移 ---
                      if (context.mounted) {
                        const LoginRoute().go(context);
                      }
                    } on Exception catch (e) {
                      if (context.mounted) {
                        ErrorHandler.showSnackBar(
                          context,
                          e,
                        );
                      }
                    }
                  },
                ),
              ],
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
