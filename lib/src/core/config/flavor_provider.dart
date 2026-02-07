import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flavor_provider.g.dart';

/// Flavorを扱うProvider
@Riverpod(keepAlive: true)
Flavor flavor(Ref ref) {
  throw UnimplementedError();
}

/// Flavorの定義
enum Flavor {
  /// ローカル環境
  local,

  /// 開発環境
  dev,

  /// ステージング環境
  stg,

  /// 本番環境
  prod;

  /// 文字列からFlavorに変換する
  static Flavor fromString(String value) {
    try {
      return values.byName(value.toLowerCase());
    } on Exception catch (_) {
      throw ArgumentError(
        'Invalid flavor: "$value". Available flavors are: '
        '${values.map((f) => f.name).join(', ')}',
      );
    }
  }
}
