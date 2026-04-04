import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 設定画面ウィジェット
class SettingsScreen extends ConsumerWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);
    final l10n = AppLocalizations.of(context)!;
    final useAuth = ref.watch(useFirebaseAuthProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: configAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tuple) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // テーマ設定セクション
              _ThemeSection(currentMode: tuple.theme),
              const SizedBox(height: 32),

              // 言語設定セクション
              _LocaleSection(currentLocale: tuple.locale),

              if (useAuth) ...[
                const SizedBox(height: 32),
                // ログアウトボタン
                const _LogoutButton(),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// テーマ設定セクション
class _ThemeSection extends ConsumerWidget {
  const _ThemeSection({required this.currentMode});

  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeModeNotifier = ref.read(themeModeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsThemeSection),
        const SizedBox(height: 8),
        DropdownButton<ThemeMode>(
          value: currentMode,
          onChanged: (v) async {
            if (v != null) await themeModeNotifier.set(v);
          },
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(l10n.settingsThemeSystem),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(l10n.settingsThemeLight),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(l10n.settingsThemeDark),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(l10n.settingsThemeToggle),
          value: currentMode == ThemeMode.dark,
          onChanged: (_) => themeModeNotifier.toggleLightDark(),
        ),
      ],
    );
  }
}

/// 言語（ロケール）設定セクション
class _LocaleSection extends ConsumerWidget {
  const _LocaleSection({required this.currentLocale});

  final Locale? currentLocale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeNotifier = ref.read(localeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsLocaleSection),
        DropdownButton<String>(
          value: currentLocale?.languageCode,
          onChanged: (v) async {
            await localeNotifier.setLocale(v);
          },
          items: [
            DropdownMenuItem(
              child: Text(l10n.settingsLocaleSystem),
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
      ],
    );
  }
}

/// ログアウトボタン
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  // ログアウトの「ロジック」だけを独立したメソッドとして定義
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(firebaseAuthRepositoryProvider).signOut();

      if (context.mounted) {
        const LoginRoute().go(context);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ElevatedButton.icon(
      key: const Key('logout_button'),
      icon: const Icon(Icons.logout),
      label: Text(l10n.logout),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _handleLogout(context, ref),
    );
  }
}
