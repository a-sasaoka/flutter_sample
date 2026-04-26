import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('packageInfoProvider Test', () {
    test('【異常系】オーバーライドせずに読み取った場合、ProviderExceptionでラップされたエラーがスローされること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 💡 修正: Riverpodは内部エラーをProviderExceptionで包んで投げる仕様なので、それを検知する
      expect(
        () => container.read(packageInfoProvider),
        throwsA(isA<ProviderException>()),
      );
    });

    test('【正常系】オーバーライドしたPackageInfoのモックデータが正しく取得できること', () {
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.example.test_app',
        version: '1.0.0',
        buildNumber: '100',
      );

      final container = ProviderContainer(
        overrides: [
          packageInfoProvider.overrideWithValue(mockPackageInfo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(packageInfoProvider);

      expect(result, equals(mockPackageInfo));
      expect(result.appName, 'Test App');
      expect(result.packageName, 'com.example.test_app');
      expect(result.version, '1.0.0');
      expect(result.buildNumber, '100');
    });
  });
}
