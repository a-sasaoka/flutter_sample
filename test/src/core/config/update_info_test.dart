// 👇 インポートパスはご自身の環境に合わせて調整してください
import 'package:flutter_sample/src/core/config/update_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateInfo テスト', () {
    // テスト用の固定日時を用意（ISO8601形式の文字列としてJSONに入ってくる想定）
    final mockDate = DateTime(2026, 3, 21, 12);
    final mockDateIso = mockDate.toIso8601String();

    test('fromJson() から正しくモデルが生成されること', () {
      // Arrange: APIから返ってくる想定のJSONデータ
      final json = {
        'requiredVersion': '1.2.0',
        'enabledAt': mockDateIso,
        'canCancel': true,
      };

      // Act
      final updateInfo = UpdateInfo.fromJson(json);

      // Assert
      expect(updateInfo.requiredVersion, equals('1.2.0'));
      expect(updateInfo.enabledAt, equals(mockDate)); // DateTime型に復元されているか
      expect(updateInfo.canCancel, isTrue);
    });

    test('fromJson() で canCancel が省略された場合、デフォルトで false になること', () {
      // Arrange: canCancel を含まないJSONデータ
      final json = {
        'requiredVersion': '1.0.0',
        'enabledAt': mockDateIso,
      };

      // Act
      final updateInfo = UpdateInfo.fromJson(json);

      // Assert
      expect(updateInfo.requiredVersion, equals('1.0.0'));
      // 🔥 @Default(false) が正しく機能しているかどうかの非常に重要なテスト！
      expect(updateInfo.canCancel, isFalse);
    });

    test('toJson() で正しいMap形式に変換されること', () {
      // Arrange
      final updateInfo = UpdateInfo(
        requiredVersion: '2.0.0',
        enabledAt: mockDate,
      );

      // Act
      final json = updateInfo.toJson();

      // Assert: キー名にタイポがないか、正しく変換されているかを確認
      expect(json['requiredVersion'], equals('2.0.0'));
      expect(json['enabledAt'], equals(mockDateIso));
      expect(json['canCancel'], isFalse);
    });
  });
}
