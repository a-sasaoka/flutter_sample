import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/widgets/offline_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../golden_test_helper.dart';

/// テスト中にオンライン状態を動的に変更するための通知クラス
class _TestOnlineNotifier extends Notifier<bool> {
  _TestOnlineNotifier({required bool initial}) : _initial = initial;

  final bool _initial;

  @override
  bool build() => _initial;

  /// 現在のオンライン状態を取得する
  bool get isOnline => state;

  /// オンライン状態を更新するセッター
  set isOnline(bool value) => state = value;
}

/// ゴールデンテスト用にオンライン復旧状態（緑色バナー）を再現するラッパーウィジェット
class _RecoveryBannerWrapper extends StatefulWidget {
  const _RecoveryBannerWrapper({required this.child, required this.notifier});

  final Widget child;
  final _TestOnlineNotifier notifier;

  @override
  State<_RecoveryBannerWrapper> createState() => _RecoveryBannerWrapperState();
}

class _RecoveryBannerWrapperState extends State<_RecoveryBannerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.notifier.isOnline = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  group('OfflineBanner Golden Tests', () {
    Widget buildBannerForGolden({
      required ThemeMode themeMode,
      required bool isOnline,
      bool isRecovery = false,
    }) {
      final notifier = _TestOnlineNotifier(initial: !isRecovery && isOnline);

      final testOnlineProvider = NotifierProvider<_TestOnlineNotifier, bool>(
        () => notifier,
      );

      final content = ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => ref.watch(testOnlineProvider)),
        ],
        child: buildGoldenTestApp(
          themeMode: themeMode,
          home: const Scaffold(
            body: Stack(
              children: [
                Center(child: Text('Screen Content')),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: OfflineBanner(
                    animationDuration: Duration(milliseconds: 100),
                    restoreDisplayDuration: Duration(seconds: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (isRecovery) {
        return _RecoveryBannerWrapper(notifier: notifier, child: content);
      }
      return content;
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'OfflineBanner の描画 (オフライン赤帯・復旧緑帯 / ライト・ダーク)',
      fileName: 'offline_banner',
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Offline - Light Mode',
            child: SizedBox(
              width: 390,
              height: 200,
              child: buildBannerForGolden(
                themeMode: ThemeMode.light,
                isOnline: false,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Offline - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 200,
              child: buildBannerForGolden(
                themeMode: ThemeMode.dark,
                isOnline: false,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Recovery - Light Mode',
            child: SizedBox(
              width: 390,
              height: 200,
              child: buildBannerForGolden(
                themeMode: ThemeMode.light,
                isOnline: true,
                isRecovery: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Recovery - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 200,
              child: buildBannerForGolden(
                themeMode: ThemeMode.dark,
                isOnline: true,
                isRecovery: true,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
