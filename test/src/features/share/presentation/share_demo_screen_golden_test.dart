import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/share/application/share_service.dart';
import 'package:flutter_sample/src/features/share/presentation/share_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../golden_test_helper.dart';

class MockShareService extends Mock implements ShareService {}

void main() {
  group('ShareDemoScreen Golden Tests', () {
    late MockShareService mockShareService;

    setUp(() {
      mockShareService = MockShareService();
    });

    Widget buildScreenForGolden({required ThemeMode themeMode}) {
      return ProviderScope(
        overrides: [shareServiceProvider.overrideWithValue(mockShareService)],
        child: buildGoldenTestApp(
          home: const ShareDemoScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'ShareDemoScreen の描画',
      fileName: 'share_demo_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Theme',
            child: SizedBox(
              width: 390,
              height: 1000,
              child: buildScreenForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Theme',
            child: SizedBox(
              width: 390,
              height: 1000,
              child: buildScreenForGolden(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  });
}
