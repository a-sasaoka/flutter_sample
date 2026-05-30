import 'package:checks/checks.dart';
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
      check(address.city).equals('Tokyo');
      check(address.street).equals('Test Street');
      check(address.suite).equals('Suite 1');
    });

    test('Address.toJson', () {
      final address = Address.fromJson(dummyAddressJson);
      final json = address.toJson();
      check(json).deepEquals(dummyAddressJson);
    });

    test('UserModel.fromJson', () {
      final user = UserModel.fromJson(dummyUserJson);
      check(user.id).equals(1);
      check(user.name).equals('Test User');
      check(user.address.city).equals('Tokyo');
    });

    test('UserModel.toJson', () {
      final user = UserModel.fromJson(dummyUserJson);
      final json = user.toJson();

      check(json['id']).equals(1);
      check(json['name']).equals('Test User');
      // 💡 AddressがMapになっていない（Objectのまま）場合の挙動に合わせる
      check(json['address']).isA<Address>();
      check((json['address'] as Address).city).equals('Tokyo');
    });

    test('UserModel equality', () {
      final user1 = UserModel.fromJson(dummyUserJson);
      final user2 = UserModel.fromJson(dummyUserJson);
      check(user1).equals(user2);
      check(user1.hashCode).equals(user2.hashCode);
    });
  });
}
