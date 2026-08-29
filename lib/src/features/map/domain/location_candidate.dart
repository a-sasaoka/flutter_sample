import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_candidate.freezed.dart';

/// 🗺️ 地図検索の候補地情報モデル
@freezed
sealed class LocationCandidate with _$LocationCandidate {
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

/// 🗺️ LocationCandidate の拡張機能
extension LocationCandidateX on LocationCandidate {
  /// LocationCandidate を MapSpot に変換する
  MapSpot toMapSpot() {
    return MapSpot(
      id: placeId ?? 'search_${latitude}_$longitude',
      name: name,
      category: _mapPrimaryTypeToCategory(primaryType),
      latitude: latitude,
      longitude: longitude,
      address: address,
      rating: rating,
    );
  }

  /// Places API の primaryType を SpotCategory にマッピングする
  SpotCategory _mapPrimaryTypeToCategory(String? type) {
    if (type == null) {
      return SpotCategory.other;
    }
    return switch (type.toLowerCase()) {
      'cafe' || 'coffee_shop' => SpotCategory.cafe,
      'park' || 'national_park' => SpotCategory.park,
      'restaurant' || 'food' || 'bar' => SpotCategory.restaurant,
      'tourist_attraction' ||
      'museum' ||
      'historical_landmark' ||
      'point_of_interest' => SpotCategory.sightseeing,
      'shopping_mall' ||
      'store' ||
      'supermarket' ||
      'department_store' => SpotCategory.shopping,
      _ => SpotCategory.other,
    };
  }
}
