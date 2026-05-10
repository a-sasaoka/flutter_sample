import 'package:flutter_sample/src/features/user/domain/address.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel & Address', () {
    final dummyAddressJson = {
      'city': 'Tokyo',
      'street': 'Test Street',
      'suite': 'Suite 1',
    };

    final dummyUserJson = {
      'id': 1,
      'name': 'Test User',
      'email': 'test@example.com',
      'phone': '123-456-7890',
      'website': 'example.com',
      'address': dummyAddressJson,
    };

    test('Address.fromJson', () {
      final address = Address.fromJson(dummyAddressJson);
      expect(address.city, 'Tokyo');
      expect(address.street, 'Test Street');
      expect(address.suite, 'Suite 1');
    });

    test('Address.toJson', () {
      final address = Address.fromJson(dummyAddressJson);
      final json = address.toJson();
      expect(json, dummyAddressJson);
    });

    test('UserModel.fromJson', () {
      final user = UserModel.fromJson(dummyUserJson);
      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.address.city, 'Tokyo');
    });

    test('UserModel.toJson', () {
      final user = UserModel.fromJson(dummyUserJson);
      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test User');
      // 💡 AddressがMapになっていない（Objectのまま）場合の挙動に合わせる
      expect(json['address'], isA<Address>());
      expect((json['address'] as Address).city, 'Tokyo');
    });

    test('UserModel equality', () {
      final user1 = UserModel.fromJson(dummyUserJson);
      final user2 = UserModel.fromJson(dummyUserJson);
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });
}
