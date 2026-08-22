import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/lottie_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../golden_test_helper.dart';

void main() {
  group('LottieDemoScreen Golden Tests', () {
    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'LottieDemoScreen の描画 (ライト/ダークモード)',
      fileName: 'lottie_demo_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 1000,
              child: buildGoldenTestApp(
                home: const LottieDemoScreen(animate: false),
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 1000,
              child: buildGoldenTestApp(
                home: const LottieDemoScreen(animate: false),
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
