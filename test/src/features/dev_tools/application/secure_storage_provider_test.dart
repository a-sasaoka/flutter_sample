// ignore_for_file: document_ignores, cascade_invocations
import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/application/secure_storage_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureStorageItems Provider Tests', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build fetches initial secure storage values', () async {
      final mockData = {'token': 'secret_value'};
      when(() => mockStorage.readAll()).thenAnswer((_) async => mockData);

      final container = createContainer();
      container.listen(secureStorageItemsProvider, (previous, next) {});

      final state = await container.read(secureStorageItemsProvider.future);
      check(state).deepEquals(mockData);
      verify(() => mockStorage.readAll()).called(1);
    });

    test('set updates value and returns updated map', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});
      when(
        () => mockStorage.readAll(),
      ).thenAnswer((_) async => {'key1': 'val1'});

      final container = createContainer();
      container.listen(secureStorageItemsProvider, (previous, next) {});

      final notifier = container.read(secureStorageItemsProvider.notifier);
      await notifier.set('key1', 'val1');

      final state = await container.read(secureStorageItemsProvider.future);
      check(state).deepEquals({'key1': 'val1'});
      verify(() => mockStorage.write(key: 'key1', value: 'val1')).called(1);
    });

    test('remove deletes value and returns updated map', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async => {});
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});

      final container = createContainer();
      container.listen(secureStorageItemsProvider, (previous, next) {});

      final notifier = container.read(secureStorageItemsProvider.notifier);
      await notifier.remove('key1');

      final state = await container.read(secureStorageItemsProvider.future);
      check(state).isEmpty();
      verify(() => mockStorage.delete(key: 'key1')).called(1);
    });

    test('clear removes all keys and returns empty map', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async => {});

      final container = createContainer();
      container.listen(secureStorageItemsProvider, (previous, next) {});

      final notifier = container.read(secureStorageItemsProvider.notifier);
      await notifier.clear();

      final state = await container.read(secureStorageItemsProvider.future);
      check(state).isEmpty();
      verify(() => mockStorage.deleteAll()).called(1);
    });
  });
}
