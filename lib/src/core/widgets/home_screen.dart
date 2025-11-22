// ホーム画面。各ページへの遷移ボタンを置きます。

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ホーム画面のウィジェット
class HomeScreen extends StatefulWidget {
  /// コンストラクタ
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String appName = '';
  String bundleId = '';

  @override
  Widget build(BuildContext context) {
    // 初心者向けメモ：
    // - XXXRoute().go(context) で遷移すると履歴を置き換えになります（戻るボタンで戻れない）
    // - XXXRoute().push<void>(context) ならスタックに積む遷移です（戻るボタンで戻れる）
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.homeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppLocalizations.of(context)!.homeDescription),
          const SizedBox(height: 16),
          Text(
            '${AppLocalizations.of(context)!.homeCurrentEnv}:'
            ' ${AppEnv.environment.toUpperCase()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/undefined/path'),
            child: Text(AppLocalizations.of(context)!.homeToNotFound),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
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
        ],
      ),
    );
  }
}
