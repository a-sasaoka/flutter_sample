import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release Security Configuration Tests', () {
    test(
      'ios/Runner/Info.plist にローカル通信許可 (NSAllowsLocalNetworking) が含まれていないこと',
      () {
        // Arrange
        final infoPlistFile = File('ios/Runner/Info.plist');
        check(infoPlistFile.existsSync()).isTrue();

        // Act
        final content = infoPlistFile.readAsStringSync();

        // Assert: 本番用 Info.plist に ATS 例外設定が含まれていないことを検証
        check(content.contains('<key>NSAllowsLocalNetworking</key>')).isFalse();
        check(content.contains('<key>NSAllowsArbitraryLoads</key>')).isFalse();
      },
    );

    test(
      'android/app/src/main/AndroidManifest.xml に cleartext 許可が含まれていないこと',
      () {
        // Arrange
        final mainManifest = File('android/app/src/main/AndroidManifest.xml');
        check(mainManifest.existsSync()).isTrue();

        // Act
        final content = mainManifest.readAsStringSync();

        // Assert: 本番用 AndroidManifest.xml に cleartext 許可が含まれていないことを検証
        check(
          content.contains('android:usesCleartextTraffic="true"'),
        ).isFalse();
      },
    );
  });
}
