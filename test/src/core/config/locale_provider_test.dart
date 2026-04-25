import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesAsyncのモック
class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
  });

  /// テスト用のProviderContainerを作成するヘルパー関数
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        // SharedPreferencesAsync をモックに差し替え（DI）
        sharedPreferencesProvider.overrideWith((ref) async => mockPrefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('LocaleNotifier テスト', () {
    test('初期化時(build): 保存された言語がない場合は null を返すこと', () async {
      // Arrange: ストレージから取得した際に null が返るように設定
      when(
        () => mockPrefs.getString('locale_key'),
      ).thenAnswer((_) async => null);

      final container = createContainer();

      // Act: 初期化(build)が完了するのを待つ
      final locale = await container.read(localeProvider.future);

      // Assert
      expect(locale, isNull);
      verify(() => mockPrefs.getString('locale_key')).called(1);
    });

    test('初期化時(build): "ja" が保存されている場合は Locale("ja") を返すこと', () async {
      // Arrange: ストレージに "ja" が保存されている状態をモック
      when(
        () => mockPrefs.getString('locale_key'),
      ).thenAnswer((_) async => 'ja');

      final container = createContainer();

      // Act
      final locale = await container.read(localeProvider.future);

      // Assert
      expect(locale, equals(const Locale('ja')));
    });

    test('setLocale("en"): 英語に変更するとストレージに保存され、状態が更新されること', () async {
      // Arrange
      // 1. build時の取得処理のモック（最初は未設定とする）
      when(
        () => mockPrefs.getString('locale_key'),
      ).thenAnswer((_) async => null);
      // 2. 保存処理(setString)のモック（何もせずに完了する）
      when(
        () => mockPrefs.setString('locale_key', 'en'),
      ).thenAnswer((_) async {});

      final container = createContainer();

      // まずは初期化(build)を完了させる（※これをしないと未初期化エラーになります）
      await container.read(localeProvider.future);

      // Act: 言語を 'en' に設定
      final notifier = container.read(localeProvider.notifier);
      await notifier.setLocale('en');

      // Assert
      // 状態が Locale('en') に更新されていること
      final currentState = container.read(localeProvider).value;
      expect(currentState, equals(const Locale('en')));

      // ストレージに保存するメソッドが正しく呼ばれたこと
      verify(() => mockPrefs.setString('locale_key', 'en')).called(1);
    });

    test('setLocale(null): nullを渡すとストレージから削除され、状態がnullに戻ること', () async {
      // Arrange
      // 1. build時は "ja" が設定されていたとする
      when(
        () => mockPrefs.getString('locale_key'),
      ).thenAnswer((_) async => 'ja');
      // 2. 削除処理(remove)のモック
      when(() => mockPrefs.remove('locale_key')).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(localeProvider.future);

      // Act: システム設定(null)に戻す
      final notifier = container.read(localeProvider.notifier);
      await notifier.setLocale(null);

      // Assert
      // 状態が null に戻っていること
      final currentState = container.read(localeProvider).value;
      expect(currentState, isNull);

      // ストレージの削除メソッドが呼ばれたこと
      verify(() => mockPrefs.remove('locale_key')).called(1);
    });
  });
}
