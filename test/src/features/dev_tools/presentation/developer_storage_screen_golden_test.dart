// ignore_for_file: document_ignores, discarded_futures, directives_ordering, lines_longer_than_80_chars
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../golden_test_helper.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/developer_storage_screen.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  group('DeveloperStorageScreen Golden Tests', () {
    late MockFlutterSecureStorage mockSecureStorage;
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
      mockSecureStorage = MockFlutterSecureStorage();
      mockPrefs = MockSharedPreferencesAsync();
      store = {};
    });

    Widget buildScreenForGolden({
      required ThemeMode themeMode,
      required Map<String, Object?> prefsData,
      required Map<String, String> secureData,
      int initialIndex = 0,
    }) {
      store = Map.from(prefsData);
      setupMockSharedPreferences();
      when(
        () => mockSecureStorage.readAll(),
      ).thenAnswer((_) async => secureData);

      return ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.dev),
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
        ],
        child: buildGoldenTestApp(
          home: DeveloperStorageScreen(
            initialTabIndex: initialIndex,
          ),
          themeMode: themeMode,
        ),
      );
    }

    goldenTest(
      'DeveloperStorageScreen (SharedPreferences tab) - Data Exist',
      fileName: 'developer_storage_screen_prefs_data',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 600,
              child: buildScreenForGolden(
                themeMode: ThemeMode.light,
                prefsData: {
                  'key_string': 'Hello World',
                  'key_int': 42,
                  'key_double': 3.1415,
                  'key_bool': true,
                },
                secureData: {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 600,
              child: buildScreenForGolden(
                themeMode: ThemeMode.dark,
                prefsData: {
                  'key_string': 'Hello World',
                  'key_int': 42,
                  'key_double': 3.1415,
                  'key_bool': true,
                },
                secureData: {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'DeveloperStorageScreen (SecureStorage tab) - Data Exist',
      fileName: 'developer_storage_screen_secure_data',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 600,
              child: buildScreenForGolden(
                themeMode: ThemeMode.light,
                prefsData: {},
                secureData: {
                  'sec_token': 'abc123xyz_secure_token_value',
                  'sec_user_id': 'user_998877',
                },
                initialIndex: 1,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 600,
              child: buildScreenForGolden(
                themeMode: ThemeMode.dark,
                prefsData: {},
                secureData: {
                  'sec_token': 'abc123xyz_secure_token_value',
                  'sec_user_id': 'user_998877',
                },
                initialIndex: 1,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'DeveloperStorageScreen - Empty State',
      fileName: 'developer_storage_screen_empty',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'SharedPreferences Empty (Light)',
            child: SizedBox(
              width: 390,
              height: 400,
              child: buildScreenForGolden(
                themeMode: ThemeMode.light,
                prefsData: {},
                secureData: {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'SecureStorage Empty (Light)',
            child: SizedBox(
              width: 390,
              height: 400,
              child: buildScreenForGolden(
                themeMode: ThemeMode.light,
                prefsData: {},
                secureData: {},
                initialIndex: 1,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
