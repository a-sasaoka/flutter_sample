import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile Domain Model Tests', () {
    test('fromJson: 正常なJSONからデシリアライズできること', () {
      final json = {
        'name': 'テスト太郎',
        'email': 'test@example.com',
        'displayName': 'タロウ',
        'phone': '09012345678',
        'avatarUrl': 'https://example.com/avatar.jpg',
      };

      final profile = UserProfile.fromJson(json);

      check(profile.name).equals('テスト太郎');
      check(profile.email).equals('test@example.com');
      check(profile.displayName).equals('タロウ');
      check(profile.phone).equals('09012345678');
      check(profile.avatarUrl).equals('https://example.com/avatar.jpg');
    });

    test('fromJson: デフォルト値の確認 (displayName, phone, avatarUrlがない場合)', () {
      final json = {
        'name': 'テスト太郎',
        'email': 'test@example.com',
      };

      final profile = UserProfile.fromJson(json);

      check(profile.name).equals('テスト太郎');
      check(profile.email).equals('test@example.com');
      check(profile.displayName).equals('');
      check(profile.phone).equals('');
      check(profile.avatarUrl).equals('');
    });

    test('toJson: 正しくシリアライズできること', () {
      const profile = UserProfile(
        name: 'テスト太郎',
        email: 'test@example.com',
        displayName: 'タロウ',
        phone: '09012345678',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final json = profile.toJson();

      check(json['name']).equals('テスト太郎');
      check(json['email']).equals('test@example.com');
      check(json['displayName']).equals('タロウ');
      check(json['phone']).equals('09012345678');
      check(json['avatarUrl']).equals('https://example.com/avatar.jpg');
    });
  });
}
