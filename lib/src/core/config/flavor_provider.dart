import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flavor_provider.g.dart';

/// Flavorを扱うProvider
@Riverpod(keepAlive: true)
Flavor flavor(Ref ref) {
  throw UnimplementedError();
}

/// Flavorの定義
///
/// この enum は環境の種類の識別のみを担当します。
/// 環境ごとの具体的な設定値は [envConfig] を参照してください。
enum Flavor {
  /// ローカル環境
  local,

  /// 開発環境
  dev,

  /// ステージング環境
  stg,

  /// 本番環境
  prod,
}
