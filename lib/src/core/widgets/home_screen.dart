// ホーム画面。各ページへの遷移ボタンを置きます。

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ホーム画面のウィジェット
class HomeScreen extends ConsumerStatefulWidget {
  /// コンストラクタ
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String appName = '';
  String bundleId = '';

  @override
  Widget build(BuildContext context) {
    final updateRequest = ref.watch(updateRequestControllerProvider);

    // 初心者向けメモ：
    // - XXXRoute().go(context) で遷移すると履歴を置き換えになります（戻るボタンで戻れない）
    // - XXXRoute().push<void>(context) ならスタックに積む遷移です（戻るボタンで戻れる）
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.homeTitle)),
      body: updateRequest.when(
        data: (updateRequest) => _buildBody(context, updateRequest),
        error: (_, _) => _buildBody(context, null),
        loading: () => const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UpdateRequestType? updateRequest) {
    // メインのWidgetの描画が終わってからダイアログを表示する
    if (updateRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await VersionUpDialog.show(
          context,
          updateRequest,
          ref,
        );
      });
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppLocalizations.of(context)!.homeDescription),
        const SizedBox(height: 16),
        Text(
          '${AppLocalizations.of(context)!.homeCurrentEnv}:'
          ' ${AppEnv.environment.toUpperCase()}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => const SettingsRoute().push<void>(context),
          child: Text(AppLocalizations.of(context)!.homeToSettings),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => const SampleRoute().push<void>(context),
          child: Text(AppLocalizations.of(context)!.homeToSample),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => const UserListRoute().push<void>(context),
          child: Text(AppLocalizations.of(context)!.homeToUserList),
        ),
        if (AppEnv.useFirebaseAuth) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => const ResetPasswordRoute().push<void>(context),
            child: Text(
              AppLocalizations.of(context)!.homeToResetPassword,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go('/undefined/path'),
          child: Text(AppLocalizations.of(context)!.homeToNotFound),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final info = await PackageInfo.fromPlatform();
            setState(() {
              appName = info.appName;
              bundleId = info
                  .packageName; // ← Android: applicationId / iOS: bundleIdentifier
            });
          },
          child: Text(AppLocalizations.of(context)!.homeGetAppInfo),
        ),
        Text('${AppLocalizations.of(context)!.homeAppName}: $appName'),
        Text('${AppLocalizations.of(context)!.homeBundleId}: $bundleId'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            FirebaseCrashlytics.instance.crash();
          },
          child: Text(AppLocalizations.of(context)!.homeCrashTest),
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
          child: Text(AppLocalizations.of(context)!.homeAnalyticsTest),
        ),
      ],
    );
  }
}
