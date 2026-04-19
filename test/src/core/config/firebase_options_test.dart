import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sample/src/core/config/firebase_options.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Flutterの内部機能（TargetPlatformなど）にアクセスするため、念のため初期化しておきます
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('firebaseOptionsWithFlavor テスト', () {
    test('定義されているすべてのFlavorに対して、正常にFirebaseOptionsが返されること', () {
      // Assert
      // Flavor.values を使って、定義されているすべてのFlavorをループで回してテストします
      for (final flavor in Flavor.values) {
        final options = firebaseOptionsWithFlavor(flavor);

        // ちゃんと FirebaseOptions のインスタンスが返ってきているか（nullやエラーにならないか）を確認
        expect(
          options,
          isA<FirebaseOptions>(),
          reason: '${flavor.name} 環境の FirebaseOptions が正しく取得できませんでした',
        );
      }
    });
  });
}
