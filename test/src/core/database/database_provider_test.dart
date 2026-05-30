import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('databaseProvider', () {
    test('appDatabaseProvider が AppDatabase のインスタンスを返すこと', () {
      // 内部で呼ばれる getApplicationDocumentsDirectory() のためのモック
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory') {
              return '.'; // ダミーパス
            }
            return null;
          });

      final container = ProviderContainer(
        overrides: [
          // Loggerのモック（または単なるインスタンス）を設定
          loggerProvider.overrideWithValue(Talker()),
        ],
      );
      addTearDown(container.dispose);

      final db = container.read(appDatabaseProvider);

      // 生成されたインスタンスが AppDatabase であることを検証
      check(db).isA<AppDatabase>();
    });
  });
}
