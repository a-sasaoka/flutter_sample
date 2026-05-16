import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/firebase_crashlytics_provider.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// ホーム画面のウィジェット
class HomeScreen extends HookConsumerWidget {
  /// コンストラクタ
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateRequest = ref.watch(updateRequestControllerProvider);
    final l10n = context.l10n;

    final appName = useState('');
    final bundleId = useState('');

    final flavor = ref.watch(flavorProvider);
    final envConfig = ref.watch(envConfigProvider);

    // データの変化を「監視」し、アップデート情報が届いた時だけ1回ダイアログを出します
    ref.listen(updateRequestControllerProvider, (previous, next) async {
      final requestType = next.value;
      if (next.hasValue &&
          requestType != null &&
          requestType != UpdateRequestType.not) {
        // すでにキャンセル済み（「後で」を押した）の場合は表示しない
        if (ref.read(cancelControllerProvider)) {
          return;
        }

        await VersionUpDialog.show(
          context,
          isCancelable: requestType == UpdateRequestType.cancelable,
          onCancel: () {
            ref.read(cancelControllerProvider.notifier).clickCancel();
          },
          onUpdate: () {
            // 本来はここで各OSのストアに飛ばす.
            ref.read(loggerProvider).info('Update button tapped');
          },
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => const SettingsRoute().push<void>(context),
            tooltip: l10n.homeToSettings,
          ),
        ],
      ),
      body: updateRequest.when(
        data: (_) => _HomeBody(
          flavor: flavor,
          useFirebaseAuth: envConfig.useFirebaseAuth,
          appName: appName.value,
          bundleId: bundleId.value,
          onGetAppInfo: () {
            final info = ref.read(packageInfoProvider);
            appName.value = info.appName;
            bundleId.value = info.packageName;
          },
        ),
        error: (e, st) => _HomeBody(
          flavor: flavor,
          useFirebaseAuth: envConfig.useFirebaseAuth,
          appName: appName.value,
          bundleId: bundleId.value,
          onGetAppInfo: () {
            final info = ref.read(packageInfoProvider);
            appName.value = info.appName;
            bundleId.value = info.packageName;
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.flavor,
    required this.useFirebaseAuth,
    required this.appName,
    required this.bundleId,
    required this.onGetAppInfo,
  });

  final Flavor flavor;
  final bool useFirebaseAuth;
  final String appName;
  final String bundleId;
  final VoidCallback onGetAppInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // 環境情報ヘッダー
        _SectionHeader(
          title: l10n.homeCurrentEnv,
          trailing: Chip(
            label: Text(
              flavor.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: colorScheme.secondaryContainer,
            side: BorderSide.none,
          ),
        ),
        const SizedBox(height: 16),

        // メイン機能カード
        Card(
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.chat_outlined,
                title: l10n.homeToChat,
                onTap: () => const ChatRoute().push<void>(context),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                icon: Icons.edit_note_outlined,
                title: l10n.homeToMemos,
                onTap: () => const MemosRoute().push<void>(context),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                icon: Icons.bar_chart_outlined,
                title: l10n.homeToGraph,
                onTap: () => const ChartInputRoute().push<void>(context),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                icon: Icons.people_outline,
                title: l10n.homeToUserList,
                onTap: () => const UserListRoute().push<void>(context),
              ),
              if (useFirebaseAuth) ...[
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  icon: Icons.lock_reset_outlined,
                  title: l10n.homeToResetPassword,
                  onTap: () => const ResetPasswordRoute().push<void>(context),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),
        _SectionHeader(title: l10n.developerLogTitle),
        const SizedBox(height: 8),

        // 開発・テスト用ツール
        Card(
          child: Column(
            children: [
              if (flavor != Flavor.prod)
                _MenuTile(
                  icon: Icons.terminal_outlined,
                  title: l10n.developerLogTitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => TalkerScreen(
                        talker: ref.read(loggerProvider),
                        appBarTitle: l10n.developerLogTitle,
                      ),
                    ),
                  ),
                ),
              if (flavor != Flavor.prod) const Divider(height: 1, indent: 56),
              _MenuTile(
                icon: Icons.running_with_errors_outlined,
                title: l10n.homeToNotFound,
                onTap: () => context.go('/undefined/path'),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                icon: Icons.bug_report_outlined,
                title: l10n.homeCrashTest,
                onTap: () => ref.read(firebaseCrashlyticsProvider).crash(),
              ),
              const Divider(height: 1, indent: 56),
              _MenuTile(
                icon: Icons.analytics_outlined,
                title: l10n.homeAnalyticsTest,
                onTap: () async {
                  final logger = ref.read(loggerProvider);
                  final analytics = ref.read(analyticsServiceProvider);
                  try {
                    await analytics.logEvent(
                      event: AnalyticsEvent.homeButtonTapped,
                    );
                    logger.debug('🎯 logEvent sent via AnalyticsService');
                  } on Exception catch (e, st) {
                    logger.error('❌ AnalyticsService error: $e\n$st');
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        _SectionHeader(title: l10n.homeGetAppInfo),
        const SizedBox(height: 8),

        // アプリ情報カード
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (appName.isEmpty)
                  FilledButton.icon(
                    onPressed: onGetAppInfo,
                    icon: const Icon(Icons.info_outline),
                    label: Text(l10n.homeGetAppInfo),
                  )
                else ...[
                  _InfoRow(label: l10n.homeAppName, value: appName),
                  const Divider(height: 24),
                  _InfoRow(label: l10n.homeBundleId, value: bundleId),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (trailing case final Widget widget) ...[
          const Spacer(),
          widget,
        ],
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
