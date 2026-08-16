import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_candidate.freezed.dart';

/// 🗺️ 地図検索の候補地情報モデル
@freezed
abstract class LocationCandidate with _$LocationCandidate {
  /// コンストラクタ
  const factory LocationCandidate({
    required double latitude,
    required double longitude,
    required String name,
    String? address,
    String? placeId,
    String? primaryType,
    double? rating,
  }) = _LocationCandidate;
}
