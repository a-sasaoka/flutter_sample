import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
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

  group('TextScaleNotifier テスト', () {
    test(
      '初期化時(build): 保存された倍率設定がない場合は defaultScale (AppTextScale.normal) を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.textScale),
        ).thenAnswer((_) async => null);

        final container = createContainer();

        // Act
        final scale = await container.read(textScaleProvider.future);

        // Assert
        check(scale).equals(AppTextScale.normal);
        verify(() => mockPrefs.getString(SharedPrefKeys.textScale)).called(1);
      },
    );

    test('初期化時(build): "small" が保存されている場合は AppTextScale.small を返すこと', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => 'small');

      final container = createContainer();

      // Act
      final scale = await container.read(textScaleProvider.future);

      // Assert
      check(scale).equals(AppTextScale.small);
      check(scale.scale).equals(0.85);
    });

    test('初期化時(build): "large" が保存されている場合は AppTextScale.large を返すこと', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => 'large');

      final container = createContainer();

      // Act
      final scale = await container.read(textScaleProvider.future);

      // Assert
      check(scale).equals(AppTextScale.large);
      check(scale.scale).equals(1.15);
    });

    test('初期化時(build): 無効な文字列が保存されていた場合は defaultScale を返すこと', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => 'invalid_scale');

      final container = createContainer();

      // Act
      final scale = await container.read(textScaleProvider.future);

      // Assert
      check(scale).equals(AppTextScale.normal);
    });

    test('setScale(): 任意の倍率を渡すと状態が更新され、ストレージに保存されること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'large'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(textScaleProvider.future);

      // Act
      await container
          .read(textScaleProvider.notifier)
          .setScale(AppTextScale.large);

      // Assert
      final state = container.read(textScaleProvider);
      check(state).isA<AsyncData<AppTextScale>>().which(
        (data) => data.has((d) => d.value, 'value').equals(AppTextScale.large),
      );

      verify(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'large'),
      ).called(1);
    });

    test('setScale(): 連続して呼び出された場合、 '
        'SharedPreferencesAsyncの完了が逆順になっても呼び出し順(FIFO)で状態と保存が確定すること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => null);

      final firstCompleter = Completer<void>();
      final secondCompleter = Completer<void>();
      final saveOrder = <String>[];

      when(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'small'),
      ).thenAnswer((_) async {
        saveOrder.add('small_start');
        await firstCompleter.future;
        saveOrder.add('small_end');
      });

      when(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'large'),
      ).thenAnswer((_) async {
        saveOrder.add('large_start');
        await secondCompleter.future;
        saveOrder.add('large_end');
      });

      final container = createContainer();
      await container.read(textScaleProvider.future);
      final notifier = container.read(textScaleProvider.notifier);

      // Act: 1回目の呼び出しを開始（完了待ちしない）
      final firstFuture = notifier.setScale(AppTextScale.small);

      // 2回目の呼び出しを開始（1回目の保存が完了する前に呼ぶ）
      final secondFuture = notifier.setScale(AppTextScale.large);

      // 2回目のCompleterを先に完了可能にしておくが、FIFOにより1回目が完了するまで2回目の処理自体が始まらない
      secondCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      check(saveOrder).deepEquals(['small_start']);

      // 1回目のCompleterを完了させる
      firstCompleter.complete();

      // 両方の完了を待つ
      await Future.wait([firstFuture, secondFuture]);

      // Assert: 実行順が small -> large の順になっていること
      check(
        saveOrder,
      ).deepEquals(['small_start', 'small_end', 'large_start', 'large_end']);
      final state = container.read(textScaleProvider);
      check(state).isA<AsyncData<AppTextScale>>().which(
        (data) => data.has((d) => d.value, 'value').equals(AppTextScale.large),
      );
    });

    test('setScale(): 直前の保存処理で例外が発生しても、後続の保存処理が中断されずに実行されること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'small'),
      ).thenThrow(Exception('ストレージ保存エラー'));
      when(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'large'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(textScaleProvider.future);
      final notifier = container.read(textScaleProvider.notifier);

      // Act: 1回目の失敗する処理を実行
      await check(notifier.setScale(AppTextScale.small)).throws<Exception>();

      // 2回目の処理を実行
      await notifier.setScale(AppTextScale.large);

      // Assert: 2回目は正常に保存・更新される
      final state = container.read(textScaleProvider);
      check(state).isA<AsyncData<AppTextScale>>().which(
        (data) => data.has((d) => d.value, 'value').equals(AppTextScale.large),
      );
    });
  });
}
