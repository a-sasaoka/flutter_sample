// ignore_for_file: document_ignores, cascade_invocations
import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/application/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  group('SharedPreferencesItems Provider Tests', () {
    late MockSharedPreferencesAsync mockPrefs;
    late Map<String, Object?> store;

    void setupMockSharedPreferences() {
      when(() => mockPrefs.getAll()).thenAnswer((_) async => store);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((inv) async {
        final key = inv.positionalArguments[0] as String;
        final val = inv.positionalArguments[1] as String;
        store[key] = val;
      });
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((inv) async {
        final key = inv.positionalArguments[0] as String;
        final val = inv.positionalArguments[1] as int;
        store[key] = val;
      });
      when(() => mockPrefs.setDouble(any(), any())).thenAnswer((inv) async {
        final key = inv.positionalArguments[0] as String;
        final val = inv.positionalArguments[1] as double;
        store[key] = val;
      });
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((inv) async {
        final key = inv.positionalArguments[0] as String;
        final val = inv.positionalArguments[1] as bool;
        store[key] = val;
      });
      when(() => mockPrefs.remove(any())).thenAnswer((inv) async {
        final key = inv.positionalArguments[0] as String;
        store.remove(key);
      });
      when(() => mockPrefs.clear()).thenAnswer((_) async {
        store.clear();
      });
    }

    setUp(() {
      mockPrefs = MockSharedPreferencesAsync();
      store = {
        'test_string': 'hello',
        'test_int': 42,
        'test_double': 3.14,
        'test_bool': true,
      };
      setupMockSharedPreferences();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build fetches initial mock values', () async {
      final container = createContainer();

      // AutoDispose なので listen して破棄を防ぐ
      container.listen(
        sharedPreferencesItemsProvider,
        (previous, next) {},
      );

      final state = await container.read(sharedPreferencesItemsProvider.future);

      check(state)
        ..['test_string'].equals('hello')
        ..['test_int'].equals(42)
        ..['test_double'].equals(3.14)
        ..['test_bool'].equals(true);
    });

    test('set updates value and fetches map', () async {
      final container = createContainer();

      container.listen(
        sharedPreferencesItemsProvider,
        (previous, next) {},
      );

      final notifier = container.read(sharedPreferencesItemsProvider.notifier);

      await notifier.set('new_key', 'new_value');
      var state = await container.read(sharedPreferencesItemsProvider.future);
      check(state)['new_key'].equals('new_value');

      await notifier.set('test_int', 99);
      state = await container.read(sharedPreferencesItemsProvider.future);
      check(state)['test_int'].equals(99);

      await notifier.set('test_double', 5.55);
      state = await container.read(sharedPreferencesItemsProvider.future);
      check(state)['test_double'].equals(5.55);

      // サポートされていない型はArgumentErrorを持つAsyncErrorをセットすることを確認
      await notifier.set('unsupported', DateTime.now());
      final finalState = container.read(sharedPreferencesItemsProvider);
      check(finalState).isA<AsyncError<Map<String, Object?>>>();
      check(finalState.error).isA<ArgumentError>();
    });

    test('remove deletes value', () async {
      final container = createContainer();

      container.listen(
        sharedPreferencesItemsProvider,
        (previous, next) {},
      );

      final notifier = container.read(sharedPreferencesItemsProvider.notifier);

      await notifier.remove('test_string');
      final state = await container.read(sharedPreferencesItemsProvider.future);
      check(state.containsKey('test_string')).isFalse();
    });

    test('clear removes all keys', () async {
      final container = createContainer();

      container.listen(
        sharedPreferencesItemsProvider,
        (previous, next) {},
      );

      final notifier = container.read(sharedPreferencesItemsProvider.notifier);

      await notifier.clear();
      final state = await container.read(sharedPreferencesItemsProvider.future);
      check(state).isEmpty();
    });
  });
}
