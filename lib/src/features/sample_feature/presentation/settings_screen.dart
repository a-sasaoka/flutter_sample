// テーマモードの切り替えUI（ドロップダウン + ダークモードの簡易スイッチ）

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 設定画面ウィジェット
class SettingsScreen extends ConsumerWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // アプリ全体の設定をまとめて取得
    final configAsync = ref.watch(appConfigProvider);

    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: configAsync.when(
        data: (tuple) {
          final themeModeNotifier = ref.read(themeModeProvider.notifier);
          final localeNotifier = ref.read(localeProvider.notifier);
          final mode = tuple.theme;
          final locale = tuple.locale;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppLocalizations.of(context)!.settingsThemeSection),
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
                      AppLocalizations.of(context)!.settingsThemeSystem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(
                      AppLocalizations.of(context)!.settingsThemeLight,
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(
                      AppLocalizations.of(context)!.settingsThemeDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsThemeToggle),
                value: mode == ThemeMode.dark,
                onChanged: (_) => themeModeNotifier.toggleLightDark(),
              ),
              const SizedBox(height: 32),
              Text(AppLocalizations.of(context)!.settingsLocaleSection),
              DropdownButton<String>(
                value: locale?.languageCode,
                onChanged: (v) async {
                  await localeNotifier.setLocale(v);
                },
                items: [
                  DropdownMenuItem(
                    child: Text(
                      AppLocalizations.of(context)!.settingsLocaleSystem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ja',
                    child: Text(AppLocalizations.of(context)!.settingsLocaleJa),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(AppLocalizations.of(context)!.settingsLocaleEn),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(localizations!.hello),
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
