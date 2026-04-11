import 'dart:async'; // StreamControllerを使うために追加

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

void main() {
  ProviderContainer createContainer({
    List<Override> overrides = const [],
  }) {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  group('isOnlineProvider のテスト', () {
    test('接続状態がまだ取得できていない（null）場合は、trueを返すこと', () {
      final container = createContainer(
        overrides: [
          // 【修正】ずっとローディング中（値がまだ来ない）状態を再現
          connectivityProvider.overrideWith(
            (ref) => StreamController<List<ConnectivityResult>>().stream,
          ),
        ],
      );

      // 【最大の修正ポイント✨】
      // readの代わりにlistenを使い、テスト中プロバイダーが破棄されないように「監視員」を置く
      final subscription = container.listen(isOnlineProvider, (_, _) {});

      // 監視員経由で現在の値を読み取る
      expect(subscription.read(), isTrue);
    });

    test('接続状態が「none（未接続）」の場合は、falseを返すこと', () async {
      final container = createContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.none]),
          ),
        ],
      );

      // 監視員を配置
      final subscription = container.listen(isOnlineProvider, (_, _) {});

      // Streamから最初の値が流れてくるのを待つ
      await container.read(connectivityProvider.future);

      // 監視員経由で値を確認
      expect(subscription.read(), isFalse);
    });

    test('接続状態に「none」が含まれていない（Wi-Fi等に接続中）場合は、trueを返すこと', () async {
      final container = createContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
      );

      // 監視員を配置
      final subscription = container.listen(isOnlineProvider, (_, _) {});

      // 値が流れてくるのを待つ
      await container.read(connectivityProvider.future);

      expect(subscription.read(), isTrue);
    });

    test('複数の接続状態があり、「none」が含まれていない場合は、trueを返すこと', () async {
      final container = createContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value([
              ConnectivityResult.mobile,
              ConnectivityResult.vpn,
            ]),
          ),
        ],
      );

      // 監視員を配置
      final subscription = container.listen(isOnlineProvider, (_, _) {});

      // 値が流れてくるのを待つ
      await container.read(connectivityProvider.future);

      expect(subscription.read(), isTrue);
    });
  });
}
