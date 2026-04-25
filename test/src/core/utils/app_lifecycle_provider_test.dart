import 'package:flutter/widgets.dart';
import 'package:flutter_sample/src/core/utils/app_lifecycle_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  // 【重要】WidgetsBinding（Flutterのコア機能）を使うテストでは、
  // 最初にこの初期化メソッドを呼ぶ必要があります。
  TestWidgetsFlutterBinding.ensureInitialized();

  // テスト用のProviderContainerを作成・破棄する便利関数
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('appLifecycleProvider のテスト', () {
    test('初期状態は、現在のシステムのライフサイクル状態（テスト環境では通常 resumed）になること', () {
      final container = createContainer();

      // プロバイダーが自動破棄（AutoDispose）されないように監視員を置く
      final subscription = container.listen(appLifecycleProvider, (_, _) {});

      // 初期状態を確認
      final initialState = subscription.read();

      // テスト環境起動時はデフォルトで resumed になる仕様です
      expect(initialState, AppLifecycleState.resumed);
    });

    test('システムのライフサイクルが変化した時、プロバイダーのStateが正しく更新されること', () {
      final container = createContainer();
      final subscription = container.listen(appLifecycleProvider, (_, _) {});

      // 1. アプリがバックグラウンドに移動した（paused）状態をシミュレート
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );

      // 状態が paused に更新されていることを確認
      expect(subscription.read(), AppLifecycleState.paused);

      // 2. アプリが非アクティブ（inactive: スワイプでタスク一覧を出している時など）をシミュレート
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );

      expect(subscription.read(), AppLifecycleState.inactive);

      // 3. アプリが再びフォアグラウンドに戻ってきた（resumed）状態をシミュレート
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      expect(subscription.read(), AppLifecycleState.resumed);
    });

    test('プロバイダーが破棄(dispose)された時、エラーが発生しないこと', () {
      // ※Riverpodの onDispose で正しく removeObserver されているかを
      // 厳密にテストするのはFlutterの仕様上少し難しいのですが、
      // 少なくともコンテナを破棄した際にクラッシュしないことを担保します。

      final _ = createContainer()
        ..listen(appLifecycleProvider, (_, _) {})
        // readしてプロバイダーを初期化
        ..read(appLifecycleProvider)
        // コンテナを破棄（ここで onDispose が呼ばれる）
        ..dispose();

      // 破棄後にライフサイクルが変わってもエラー（メモリリーク等）が起きないことを確認
      expect(
        () => WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        ),
        returnsNormally,
      );
    });
  });
}
