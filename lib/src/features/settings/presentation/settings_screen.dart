import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 設定画面ウィジェット
class SettingsScreen extends ConsumerWidget {
  /// コンストラクタ
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isAuthed = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // プロフィール設定セクション
          _SectionHeader(title: '👤 ${l10n.profileTitle}'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.profileTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                const ProfileEditRoute().go(context);
              },
            ),
          ),
          const SizedBox(height: 32),

          // テーマ設定セクション
          _SectionHeader(title: l10n.settingsThemeSection),
          const SizedBox(height: 8),
          const _ThemeCard(),
          const SizedBox(height: 32),

          // テーマカラー設定セクション
          _SectionHeader(title: l10n.settingsColorSection),
          const SizedBox(height: 8),
          const _ThemeColorCard(),
          const SizedBox(height: 32),

          // 文字サイズ設定セクション
          _SectionHeader(title: l10n.settingsTextScaleSection),
          const SizedBox(height: 8),
          const _TextScaleCard(),
          const SizedBox(height: 32),

          // 言語設定セクション
          _SectionHeader(title: l10n.settingsLocaleSection),
          const SizedBox(height: 8),
          const _LocaleCard(),
          const SizedBox(height: 32),

          // 法的情報セクション
          _SectionHeader(title: l10n.settingsLegalSection),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('terms_of_service_tile'),
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.termsOfServiceTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => const TermsRoute().push<void>(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('privacy_policy_tile'),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacyPolicyTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => const PrivacyPolicyRoute().push<void>(context),
                ),
              ],
            ),
          ),

          if (isAuthed) ...[
            const SizedBox(height: 48),
            // ログアウトボタン
            const _LogoutButton(),
          ],
        ],
      ),
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
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeProvider);
    final currentMode = themeAsync.value ?? ThemeMode.system;
    final l10n = context.l10n;

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.settingsThemeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.settingsThemeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.settingsThemeDark),
                    ),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (selection) async {
                    await ref
                        .read(themeModeProvider.notifier)
                        .set(selection.first);
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
            onChanged: (_) =>
                ref.read(themeModeProvider.notifier).toggleLightDark(),
          ),
        ],
      ),
    );
  }
}

/// テーマカラー設定カード
class _ThemeColorCard extends ConsumerWidget {
  const _ThemeColorCard();

  static const List<(FlexScheme, Color)> _supportedSchemes = [
    (FlexScheme.indigoM3, Colors.indigo),
    (FlexScheme.tealM3, Colors.teal),
    (FlexScheme.orangeM3, Colors.orange),
    (FlexScheme.pinkM3, Colors.pink),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScheme =
        ref.watch(themeSchemeProvider).value ??
        ThemeSchemeNotifier.defaultScheme;
    final l10n = context.l10n;

    String schemeLabel(FlexScheme scheme) => switch (scheme) {
      FlexScheme.indigoM3 => l10n.settingsColorIndigo,
      FlexScheme.tealM3 => l10n.settingsColorTeal,
      FlexScheme.orangeM3 => l10n.settingsColorOrange,
      FlexScheme.pinkM3 => l10n.settingsColorPink,
      _ => scheme.name, // coverage:ignore-line
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _supportedSchemes.map((item) {
            final (scheme, color) = item;
            final isSelected = currentScheme == scheme;

            return ChoiceChip(
              avatar: CircleAvatar(backgroundColor: color, radius: 10),
              label: Text(schemeLabel(scheme)),
              selected: isSelected,
              onSelected: (selected) async {
                if (selected) {
                  await ref
                      .read(themeSchemeProvider.notifier)
                      .setScheme(scheme);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 文字サイズ設定カード
class _TextScaleCard extends ConsumerWidget {
  const _TextScaleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScaleAsync = ref.watch(textScaleProvider);
    final currentScale = textScaleAsync.value ?? TextScaleNotifier.defaultScale;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<AppTextScale>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AppTextScale.small,
                  label: Text(l10n.settingsTextScaleSmall),
                ),
                ButtonSegment(
                  value: AppTextScale.normal,
                  label: Text(l10n.settingsTextScaleNormal),
                ),
                ButtonSegment(
                  value: AppTextScale.large,
                  label: Text(l10n.settingsTextScaleLarge),
                ),
              ],
              selected: {currentScale},
              onSelectionChanged: (selection) async {
                await ref
                    .read(textScaleProvider.notifier)
                    .setScale(selection.first);
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settingsTextScalePreview,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
              textScaler: TextScaler.linear(currentScale.scale),
            ),
          ],
        ),
      ),
    );
  }
}

/// 言語（ロケール）設定カード
class _LocaleCard extends ConsumerWidget {
  const _LocaleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.value;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(l10n.settingsLocaleSystem),
                ),
                ButtonSegment(value: 'ja', label: Text(l10n.settingsLocaleJa)),
                ButtonSegment(value: 'en', label: Text(l10n.settingsLocaleEn)),
              ],
              selected: {currentLocale?.languageCode},
              onSelectionChanged: (selection) async {
                await ref
                    .read(localeProvider.notifier)
                    .setLocale(selection.first);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${l10n.settingsPreview}: ${l10n.hello}',
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
      await ref.read(authServiceProvider).signOut();
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
