import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- モッククラス ---
class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;
  late ProviderContainer container;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 5, 17, 10)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const testKey = 'test_cache';
  const testValue = {'id': 1, 'name': 'Test'};

  group('CacheManager', () {
    test('save: データを正しい形式（JSON）で保存すること', () async {
      // Arrange
      final manager = container.read(cacheManagerProvider);
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => {});

      // Act
      await manager.save(testKey, testValue);

      // Assert
      verify(
        () => mockPrefs.setString(
          testKey,
          any(that: contains('"data":{"id":1,"name":"Test"}')),
        ),
      ).called(1);
    });

    test('getWithTimestamp: 有効期限内のキャッシュを正しく取得できること', () async {
      // Arrange
      final tsMs = DateTime(2026, 5, 17, 9, 55).millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': tsMs,
        'data': testValue,
      });
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => cacheData);
      final manager = container.read(cacheManagerProvider);

      // Act
      final (data, ts) = await manager.getWithTimestamp(testKey);

      // Assert
      check(data).isA<Map<dynamic, dynamic>>().deepEquals(testValue);
      check(ts).equals(DateTime.fromMillisecondsSinceEpoch(tsMs));
    });

    test('get: ショートカットメソッドでデータのみ取得できること', () async {
      // Arrange
      final tsMs = DateTime(2026, 5, 17, 9, 55).millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': tsMs,
        'data': testValue,
      });
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => cacheData);
      final manager = container.read(cacheManagerProvider);

      // Act
      final result = await manager.get(testKey);

      // Assert
      check(result as Map).deepEquals(testValue);
    });

    test('getWithTimestamp: 期限切れのキャッシュは削除して (null, null) を返すこと', () async {
      // Arrange
      // 10分以上前（現在 10:00 に対して 9:40）
      final tsMs = DateTime(2026, 5, 17, 9, 40).millisecondsSinceEpoch;
      final cacheData = jsonEncode({
        'timestamp': tsMs,
        'data': testValue,
      });
      when(
        () => mockPrefs.getString(testKey),
      ).thenAnswer((_) async => cacheData);
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});
      final manager = container.read(cacheManagerProvider);

      // Act
      final (data, ts) = await manager.getWithTimestamp(testKey);

      // Assert
      check(data).isNull();
      check(ts).isNull();
      verify(() => mockPrefs.remove(testKey)).called(1);
    });

    test('getWithTimestamp: キャッシュが存在しない場合は (null, null) を返すこと', () async {
      // Arrange
      when(() => mockPrefs.getString(testKey)).thenAnswer((_) async => null);
      final manager = container.read(cacheManagerProvider);

      // Act
      final (data, ts) = await manager.getWithTimestamp(testKey);

      // Assert
      check(data).isNull();
      check(ts).isNull();
    });

    test(
      'getWithTimestamp: JSONパースエラーが発生した場合は削除して (null, null) を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(testKey),
        ).thenAnswer((_) async => '{ invalid }');
        when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});
        final manager = container.read(cacheManagerProvider);

        // Act
        final (data, ts) = await manager.getWithTimestamp(testKey);

        // Assert
        check(data).isNull();
        check(ts).isNull();
        verify(() => mockPrefs.remove(testKey)).called(1);
      },
    );

    test('clear: 指定したキーのキャッシュを削除すること', () async {
      // Arrange
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => {});
      final manager = container.read(cacheManagerProvider);

      // Act
      await manager.clear(testKey);

      // Assert
      verify(() => mockPrefs.remove(testKey)).called(1);
    });
  });
}
