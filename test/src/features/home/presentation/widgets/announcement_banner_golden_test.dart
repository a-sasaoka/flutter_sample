import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/home/presentation/widgets/announcement_banner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../golden_test_helper.dart';

void main() {
  group('AnnouncementBanner Golden Tests', () {
    Widget buildBannerForGolden({
      required ThemeMode themeMode,
      required String message,
    }) {
      return buildGoldenTestApp(
        themeMode: themeMode,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AnnouncementBanner(message: message),
          ),
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'お知らせバナーの表示（ライト/ダーク）',
      fileName: 'announcement_banner',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode - With Message',
            child: SizedBox(
              width: 390,
              height: 120,
              child: buildBannerForGolden(
                themeMode: ThemeMode.light,
                message: '重要：システムメンテナンスを予定しています',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode - With Message',
            child: SizedBox(
              width: 390,
              height: 120,
              child: buildBannerForGolden(
                themeMode: ThemeMode.dark,
                message: '重要：システムメンテナンスを予定しています',
              ),
            ),
          ),
        ],
      ),
    );
  });
}
