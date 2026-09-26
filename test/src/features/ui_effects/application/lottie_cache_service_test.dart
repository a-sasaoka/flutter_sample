import 'package:checks/checks.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/features/ui_effects/application/lottie_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LottieCacheService Tests', () {
    test('preloadLottie が例外なく正常に完了すること', () async {
      // Act & Assert
      await check(
        LottieCacheService.preloadLottie(Assets.animations.successCheck.path),
      ).completes();
    });
  });
}
