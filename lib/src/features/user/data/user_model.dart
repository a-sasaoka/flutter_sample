// Freezedでユーザーモデルを定義（JSONと自動変換）

import 'package:flutter_sample/src/features/user/data/address.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// ユーザーモデル
@freezed
sealed class UserModel with _$UserModel {
  /// ユーザーモデルのファクトリコンストラクタ
  const factory UserModel({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String website,
    required Address address,
  }) = _UserModel;

  /// JSONからUserModelオブジェクトを生成するファクトリコンストラクタ
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
