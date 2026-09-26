import 'package:lottie/lottie.dart';

/// Lottie アニメーションの事前ロードとキャッシュを管理するサービス
abstract final class LottieCacheService {
  /// アプリ起動時や画面描画前に呼び出し、LottieのJSONをパースしてメモリにキャッシュする
  ///
  /// 事前にパースしておくことで、画面表示時やボタンタップ直後のチラつき・描画カクつき（Jank）を防止します。
  static Future<void> preloadLottie(String assetPath) async {
    await AssetLottie(assetPath).load();
  }
}
