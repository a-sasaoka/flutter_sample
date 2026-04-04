// ホーム画面。各ページへの遷移ボタンを置きます。

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/firebase_crashlytics_provider.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ホーム画面のウィジェット
class HomeScreen extends HookConsumerWidget {
  /// コンストラクタ
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateRequest = ref.watch(updateRequestControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    final appName = useState('');
    final bundleId = useState('');

    final flavor = ref.watch(flavorProvider);
    final useFirebaseAuth = ref.watch(useFirebaseAuthProvider);

    // データの変化を「監視」し、アップデート情報が届いた時だけ1回ダイアログを出します
    ref.listen(updateRequestControllerProvider, (previous, next) async {
      if (next.hasValue && next.value != null) {
        await VersionUpDialog.show(context, next.value!, ref);
      }
    });

    Widget buildBody() {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.homeDescription),
          const SizedBox(height: 16),
          Text(
            '${l10n.homeCurrentEnv}: ${flavor.name.toUpperCase()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => const SettingsRoute().push<void>(context),
            child: Text(l10n.homeToSettings),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => const SampleRoute().push<void>(context),
            child: Text(l10n.homeToSample),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => const UserListRoute().push<void>(context),
            child: Text(l10n.homeToUserList),
          ),
          if (useFirebaseAuth) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => const ResetPasswordRoute().push<void>(context),
              child: Text(l10n.homeToResetPassword),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => const ChatRoute().push<void>(context),
            child: Text(l10n.homeToChat),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/undefined/path'),
            child: Text(l10n.homeToNotFound),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final appPackageInfo = ref.read(packageInfoProvider);

              appName.value = appPackageInfo.appName;
              bundleId.value = appPackageInfo.packageName;
            },
            child: Text(l10n.homeGetAppInfo),
          ),
          Text(
            '${l10n.homeAppName}: ${appName.value}',
          ),
          Text('${l10n.homeBundleId}: ${bundleId.value}'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(firebaseCrashlyticsProvider).crash();
            },
            child: Text(l10n.homeCrashTest),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final logger = ref.read(loggerProvider);
              final analytics = ref.read(analyticsServiceProvider);

              try {
                await analytics.logEvent(
                  event: AnalyticsEvent.homeButtonTapped,
                );
                logger.d('🎯 logEvent sent via AnalyticsService');
              } on Exception catch (e, st) {
                logger.e('❌ AnalyticsService error: $e\n$st');
              }
            },
            child: Text(l10n.homeAnalyticsTest),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: updateRequest.when(
        data: (_) => buildBody(),
        error: (_, _) => buildBody(),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
