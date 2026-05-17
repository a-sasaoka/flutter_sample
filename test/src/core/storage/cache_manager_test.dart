import 'dart:convert';

import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesAsync をモックする
class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;
  late ProviderContainer container;
  final fixedDateTime = DateTime(2024, 1, 1, 12);

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        clockProvider.overrideWithValue(() => fixedDateTime),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CacheManager', () {
    const testKey = 'test_key';
    const testValue = {'id': 1, 'name': 'test'};

    test('save: データを正しい形式（JSON）で保存すること', () async {
      // Arrange
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => {});
      final manager = container.read(cacheManagerProvider);

      // Act
      await manager.save(testKey, testValue);

      // Assert
      verify(
        () => mockPrefs.setString(
          testKey,
          any(that: contains('"data":{"id":1')),
        ),
      ).called(1);
    });

    test('get: 有効期限内のキャッシュを正しく取得できること', () async {
      // Arrange
      final now = fixedDateTime.millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': now,
        'data': testValue,
      });
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => cacheData);
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.get(testKey);

      // Assert
      expect(result, testValue);
    });

    test('get: キャッシュが存在しない場合は null を返すこと', () async {
      // Arrange
      when(() => mockPrefs.getString(testKey)).thenAnswer((_) async => null);
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.get(testKey);

      // Assert
      expect(result, isNull);
    });

    test('get: 期限切れのキャッシュ（10分以上経過）は削除して null を返すこと', () async {
      // Arrange
      final oldTimestamp = fixedDateTime
          .subtract(const Duration(minutes: 11))
          .millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': oldTimestamp,
        'data': testValue,
      });

      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => cacheData);
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.get(testKey);

      // Assert
      expect(result, isNull);
      verify(() => mockPrefs.remove(testKey)).called(1);
    });

    test('get: JSONパースエラーが発生した場合、キャッシュが壊れているとみなして削除し null を返すこと', () async {
      // Arrange
      const invalidJson = '{ invalid json string }';
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => invalidJson);
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});

      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.get(testKey);

      // Assert
      expect(result, isNull);
      verify(() => mockPrefs.remove(testKey)).called(1);
    });

    test('get: キャッシュのデータ構造が想定と違う場合、キャッシュが壊れているとみなして削除し null を返すこと', () async {
      // Arrange
      final invalidData = jsonEncode({
        'timestamp': 'invalid_type_timestamp',
        'data': testValue,
      });
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => invalidData);
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});

      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.get(testKey);

      // Assert
      expect(result, isNull);
      verify(() => mockPrefs.remove(testKey)).called(1);
    });

    test('clear: 指定したキーのキャッシュを削除すること', () async {
      // Arrange
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});
      final manager = container.read(cacheManagerProvider);

      // Act
      await manager.clear(testKey);

      // Assert
      verify(() => mockPrefs.remove(testKey)).called(1);
    });

    test('getTimestamp: キャッシュの保存日時を正しく取得できること', () async {
      // Arrange
      final timestamp = DateTime(2026, 5, 17, 10).millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': timestamp,
        'data': testValue,
      });
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => cacheData);
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.getTimestamp(testKey);

      // Assert
      expect(result, DateTime.fromMillisecondsSinceEpoch(timestamp));
    });

    test('getTimestamp: キャッシュが存在しない場合は null を返すこと', () async {
      // Arrange
      when(() => mockPrefs.getString(testKey)).thenAnswer((_) async => null);
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.getTimestamp(testKey);

      // Assert
      expect(result, isNull);
    });

    test('getTimestamp: JSONパースエラーが発生した場合は null を返すこと', () async {
      // Arrange
      const invalidJson = '{ invalid }';
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => invalidJson);
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.getTimestamp(testKey);

      // Assert
      expect(result, isNull);
    });
  });

  group('CacheManager ユニットテスト (Providerなし)', () {
    test('DIにより、ProviderContainerなしでも単体テストが可能であり、設定した有効期限が機能すること', () async {
      // Arrange
      final mockPrefs = MockSharedPreferencesAsync();
      final fixedDate = DateTime(2026);
      const customDuration = Duration(minutes: 1);

      // 2分前のキャッシュデータを作成
      final oldTimestamp = fixedDate
          .subtract(const Duration(minutes: 2))
          .millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': oldTimestamp,
        'data': 'expired_data',
      });

      when(() => mockPrefs.getString('any')).thenAnswer((_) async => cacheData);
      when(() => mockPrefs.remove('any')).thenAnswer((_) async => {});

      final manager = CacheManager(
        prefs: mockPrefs,
        getCurrentDateTime: () => fixedDate,
        cacheDuration: customDuration, // 1分に設定
      );

      // Act
      final result = await manager.get('any');

      // Assert
      expect(result, isNull); // 1分期限に対して2分前なので null
      verify(() => mockPrefs.remove('any')).called(1);
    });
  });
}
