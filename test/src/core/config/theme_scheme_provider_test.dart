import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
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

  /// テスト用のProviderContainerを作成するヘルパー
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ThemeSchemeNotifier テスト', () {
    test(
      '初期化時(build): 保存されたスキームがない場合は defaultScheme (indigoM3) を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.themeScheme),
        ).thenAnswer((_) async => null);

        final container = createContainer();

        // Act
        final scheme = await container.read(themeSchemeProvider.future);

        // Assert
        check(scheme).equals(FlexScheme.indigoM3);
        verify(() => mockPrefs.getString(SharedPrefKeys.themeScheme)).called(1);
      },
    );

    test('初期化時(build): "tealM3" が保存されている場合は FlexScheme.tealM3 を返すこと', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.themeScheme),
      ).thenAnswer((_) async => 'tealM3');

      final container = createContainer();

      // Act
      final scheme = await container.read(themeSchemeProvider.future);

      // Assert
      check(scheme).equals(FlexScheme.tealM3);
    });

    test('初期化時(build): 無効な文字列が保存されていた場合は defaultScheme を返すこと', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.themeScheme),
      ).thenAnswer((_) async => 'invalid_scheme');

      final container = createContainer();

      // Act
      final scheme = await container.read(themeSchemeProvider.future);

      // Assert
      check(scheme).equals(FlexScheme.indigoM3);
    });

    test('setScheme(): 任意のカラースキームを渡すと状態が更新され、ストレージに保存されること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.themeScheme),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'orangeM3'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(themeSchemeProvider.future);

      // Act
      final notifier = container.read(themeSchemeProvider.notifier);
      await notifier.setScheme(FlexScheme.orangeM3);

      // Assert
      check(
        container.read(themeSchemeProvider).value,
      ).equals(FlexScheme.orangeM3);
      verify(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'orangeM3'),
      ).called(1);
    });

    test('setScheme(): 連続して呼び出された場合、 '
        'SharedPreferencesAsyncの完了が逆順になっても呼び出し順(FIFO)で状態と保存が確定すること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.themeScheme),
      ).thenAnswer((_) async => null);

      final firstCompleter = Completer<void>();
      final secondCompleter = Completer<void>();
      final saveOrder = <String>[];

      when(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'tealM3'),
      ).thenAnswer((_) async {
        saveOrder.add('tealM3_start');
        await firstCompleter.future;
        saveOrder.add('tealM3_end');
      });

      when(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'sakura'),
      ).thenAnswer((_) async {
        saveOrder.add('sakura_start');
        await secondCompleter.future;
        saveOrder.add('sakura_end');
      });

      final container = createContainer();
      await container.read(themeSchemeProvider.future);
      final notifier = container.read(themeSchemeProvider.notifier);

      // Act: 1回目の呼び出しを開始（完了待ちしない）
      final firstFuture = notifier.setScheme(FlexScheme.tealM3);

      // 2回目の呼び出しを開始（1回目の保存が完了する前に呼ぶ）
      final secondFuture = notifier.setScheme(FlexScheme.sakura);

      // 2回目のCompleterを先に完了可能にしておくが、FIFOにより1回目が完了するまで2回目の処理自体が始まらない
      secondCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      check(saveOrder).deepEquals(['tealM3_start']);

      // 1回目のCompleterを完了させる
      firstCompleter.complete();

      // 両方の完了を待つ
      await Future.wait([firstFuture, secondFuture]);

      // Assert: 実行順が tealM3 -> sakura の順になっていること
      check(saveOrder).deepEquals([
        'tealM3_start',
        'tealM3_end',
        'sakura_start',
        'sakura_end',
      ]);
      check(
        container.read(themeSchemeProvider).value,
      ).equals(FlexScheme.sakura);
    });

    test('setScheme(): 直前の保存処理で例外が発生しても、後続の保存処理が中断されずに実行されること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.themeScheme),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'tealM3'),
      ).thenThrow(Exception('ストレージ保存エラー'));
      when(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'sakura'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(themeSchemeProvider.future);
      final notifier = container.read(themeSchemeProvider.notifier);

      // Act: 1回目の失敗する処理を実行
      await check(notifier.setScheme(FlexScheme.tealM3)).throws<Exception>();

      // 2回目の処理を実行
      await notifier.setScheme(FlexScheme.sakura);

      // Assert: 2回目は正常に保存・更新される
      check(
        container.read(themeSchemeProvider).value,
      ).equals(FlexScheme.sakura);
    });
  });
}
