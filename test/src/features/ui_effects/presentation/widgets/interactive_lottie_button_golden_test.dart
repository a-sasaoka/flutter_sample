import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/features/ui_effects/presentation/widgets/interactive_lottie_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../golden_test_helper.dart';

void main() {
  group('InteractiveLottieButton Golden Tests', () {
    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'InteractiveLottieButton の描画 (待機状態・ライト/ダーク)',
      fileName: 'interactive_lottie_button',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Idle (Light)',
            child: SizedBox(
              width: 280,
              height: 90,
              child: buildGoldenTestApp(
                home: ProviderScope(
                  child: Scaffold(
                    body: Center(
                      child: InteractiveLottieButton(
                        assetPath: Assets.animations.successCheck.path,
                        onComplete: () {},
                        animate: false,
                      ),
                    ),
                  ),
                ),
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Idle (Dark)',
            child: SizedBox(
              width: 280,
              height: 90,
              child: buildGoldenTestApp(
                home: ProviderScope(
                  child: Scaffold(
                    body: Center(
                      child: InteractiveLottieButton(
                        assetPath: Assets.animations.successCheck.path,
                        onComplete: () {},
                        animate: false,
                      ),
                    ),
                  ),
                ),
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
