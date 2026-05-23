import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 設定画面ウィジェット
class SettingsScreen extends ConsumerWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);
    final l10n = context.l10n;
    final useAuth = ref.watch(envConfigProvider).useFirebaseAuth;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: switch (configAsync) {
        AsyncData(value: final config) => () {
          final (:theme, :locale, :router) = config;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // テーマ設定セクション
              _SectionHeader(title: l10n.settingsThemeSection),
              const SizedBox(height: 8),
              _ThemeCard(currentMode: theme),
              const SizedBox(height: 32),

              // 言語設定セクション
              _SectionHeader(title: l10n.settingsLocaleSection),
              const SizedBox(height: 8),
              _LocaleCard(currentLocale: locale),

              if (useAuth) ...[
                const SizedBox(height: 48),
                // ログアウトボタン
                const _LogoutButton(),
              ],
            ],
          );
        }(),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// テーマ設定カード
class _ThemeCard extends ConsumerWidget {
  const _ThemeCard({required this.currentMode});

  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeModeNotifier = ref.read(themeModeProvider.notifier);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.settingsThemeSystem),
                      icon: const Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.settingsThemeLight),
                      icon: const Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.settingsThemeDark),
                      icon: const Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (selection) async {
                    await themeModeNotifier.set(selection.first);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(l10n.settingsThemeToggle),
            secondary: const Icon(Icons.contrast),
            value: currentMode == ThemeMode.dark,
            onChanged: (_) => themeModeNotifier.toggleLightDark(),
          ),
        ],
      ),
    );
  }
}

/// 言語（ロケール）設定カード
class _LocaleCard extends ConsumerWidget {
  const _LocaleCard({required this.currentLocale});

  final Locale? currentLocale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localeNotifier = ref.read(localeProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String?>(
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(l10n.settingsLocaleSystem),
                ),
                const ButtonSegment(
                  value: 'ja',
                  label: Text('日本語'),
                ),
                const ButtonSegment(
                  value: 'en',
                  label: Text('English'),
                ),
              ],
              selected: {currentLocale?.languageCode},
              onSelectionChanged: (selection) async {
                await localeNotifier.setLocale(selection.first);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Preview: ${l10n.hello}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ログアウトボタン
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(firebaseAuthRepositoryProvider).signOut();
    } on Exception catch (e) {
      if (context.mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return FilledButton.icon(
      key: const Key('logout_button'),
      icon: const Icon(Icons.logout),
      label: Text(l10n.logout),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      onPressed: () => _handleLogout(context, ref),
    );
  }
}
