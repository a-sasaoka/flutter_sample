// Freezedで住所モデルを定義（JSONと自動変換）

import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

/// 住所モデル
@freezed
sealed class Address with _$Address {
  /// 住所モデルのファクトリコンストラクタ
  const factory Address({
    required String city,
    required String street,
    required String suite,
  }) = _Address;

  /// JSONからAddressオブジェクトを生成するファクトリコンストラクタ
  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}
