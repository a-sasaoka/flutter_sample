import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_model.freezed.dart';

/// メモモデル
@freezed
sealed class MemoModel with _$MemoModel {
  const factory MemoModel({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDeleted,
    @Default(false) bool isSynced,
  }) = _MemoModel;
}
