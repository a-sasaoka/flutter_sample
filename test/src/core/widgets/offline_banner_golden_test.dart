import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/widgets/offline_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../golden_test_helper.dart';

void main() {
  group('OfflineBanner Golden Tests', () {
    Widget buildBannerForGolden({
      required ThemeMode themeMode,
      required bool isOnline,
    }) {
      return ProviderScope(
        overrides: [isOnlineProvider.overrideWith((ref) => isOnline)],
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
                  child: OfflineBanner(animationDuration: Duration.zero),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'OfflineBanner の描画 (オフライン赤帯 / ライト・ダーク)',
      fileName: 'offline_banner',
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
        ],
      ),
    );
  });
}
