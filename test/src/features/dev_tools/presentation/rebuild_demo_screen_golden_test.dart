import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/dev_tools/application/rebuild_demo_notifier.dart';
import 'package:flutter_sample/src/features/dev_tools/domain/rebuild_demo_state.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/rebuild_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../golden_test_helper.dart';

void main() {
  group('RebuildDemoScreen Golden Tests', () {
    Widget buildScreenForGolden({
      required ThemeMode themeMode,
      required bool isOptimized,
    }) {
      return ProviderScope(
        overrides: [
          rebuildDemoProvider.overrideWith(
            () => _FakeRebuildDemoNotifier(isOptimized: isOptimized),
          ),
        ],
        child: buildGoldenTestApp(
          home: const RebuildDemoScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'RebuildDemoScreen の描画',
      fileName: 'rebuild_demo_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Bad Mode (Light)',
            child: SizedBox(
              width: 390,
              height: 1700,
              child: buildScreenForGolden(
                themeMode: ThemeMode.light,
                isOptimized: false,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Good Mode (Light)',
            child: SizedBox(
              width: 390,
              height: 1700,
              child: buildScreenForGolden(
                themeMode: ThemeMode.light,
                isOptimized: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Bad Mode (Dark)',
            child: SizedBox(
              width: 390,
              height: 1700,
              child: buildScreenForGolden(
                themeMode: ThemeMode.dark,
                isOptimized: false,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Good Mode (Dark)',
            child: SizedBox(
              width: 390,
              height: 1700,
              child: buildScreenForGolden(
                themeMode: ThemeMode.dark,
                isOptimized: true,
              ),
            ),
          ),
        ],
      ),
    );
  });
}

class _FakeRebuildDemoNotifier extends RebuildDemoNotifier {
  _FakeRebuildDemoNotifier({required this.isOptimized});

  final bool isOptimized;

  @override
  RebuildDemoState build() {
    return RebuildDemoState.initial().copyWith(isOptimized: isOptimized);
  }
}
