import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_model.freezed.dart';

/// メモモデル
@freezed
sealed class MemoModel with _$MemoModel {
  const factory MemoModel({
    required int id,
    required String title,
    required String content,
    required DateTime createdAt,
  }) = _MemoModel;
}
