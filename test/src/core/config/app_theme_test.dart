import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme テスト', () {
    test('light() が正常に実行され、ライトモード用の ThemeData を返すこと', () {
      // Act
      final theme = AppTheme.light();

      // Assert
      // 1. ちゃんと ThemeData 型のオブジェクトが生成されているか（内部でクラッシュしていないか）
      expect(theme, isA<ThemeData>());

      // 2. 明るさ（Brightness）が正しく Light になっているか
      expect(theme.brightness, equals(Brightness.light));

      // 3. Material 3 が有効になっているか（コードの意図通りか）
      expect(theme.useMaterial3, isTrue);
    });

    test('dark() が正常に実行され、ダークモード用の ThemeData を返すこと', () {
      // Act
      final theme = AppTheme.dark();

      // Assert
      // 1. 生成の確認
      expect(theme, isA<ThemeData>());

      // 2. 明るさ（Brightness）が正しく Dark になっているか
      expect(theme.brightness, equals(Brightness.dark));

      // 3. Material 3 が有効になっているか
      expect(theme.useMaterial3, isTrue);
    });
  });
}
