import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'spot_repository.g.dart';

/// 🗺️ スポットデータを提供する Repository インターフェース
abstract class SpotRepository {
  /// 付近の推奨スポット一覧を取得
  Future<List<MapSpot>> getSpots();

  /// ID 指定でスポット情報を取得
  Future<MapSpot?> getSpotById(String id);
}

/// 🗺️ SpotRepository の標準実装（サンプルデータ提供）
class SpotRepositoryImpl implements SpotRepository {
  /// サンプルスポットデータ一覧
  static const List<MapSpot> sampleSpots = [
    MapSpot(
      id: 'spot_tokyo_tower',
      name: '東京タワー',
      category: SpotCategory.sightseeing,
      latitude: 35.6585805,
      longitude: 139.7454329,
      address: '東京都港区芝公園4-2-8',
      description: '高さ333mの総合電波塔。メインデッキ・トップデッキからの絶景が魅力です。',
      rating: 4.6,
    ),
    MapSpot(
      id: 'spot_yoyogi_park',
      name: '代々木公園',
      category: SpotCategory.park,
      latitude: 35.671736,
      longitude: 139.694945,
      address: '東京都渋谷区代々木神園町2-1',
      description: '豊かな自然と広大な芝生が広がる都会のオアシス。散策やピクニックに最適。',
      rating: 4.5,
    ),
    MapSpot(
      id: 'spot_sensoji',
      name: '浅草寺',
      category: SpotCategory.sightseeing,
      latitude: 35.714765,
      longitude: 139.796655,
      address: '東京都台東区浅草2-3-1',
      description: '都内最古の寺院。雷門や仲見世通りで賑わう人気の観光スポット。',
      rating: 4.7,
    ),
    MapSpot(
      id: 'spot_omotesando_cafe',
      name: '表参道カフェテラス',
      category: SpotCategory.cafe,
      latitude: 35.665247,
      longitude: 139.712319,
      address: '東京都港区南青山5-1-2',
      description: 'こだわり自慢のハンドドリップコーヒーと自家製スイーツが人気のカフェ。',
      rating: 4.3,
    ),
    MapSpot(
      id: 'spot_ginza_shopping',
      name: '銀座ショッピングモール',
      category: SpotCategory.shopping,
      latitude: 35.671989,
      longitude: 139.763965,
      address: '東京都中央区銀座6-10-1',
      description: '世界のトップブランドから伝統工芸品まで揃う洗練された商業施設。',
      rating: 4.4,
    ),
    MapSpot(
      id: 'spot_tsukiji_restaurant',
      name: '築地鮮魚ダイニング',
      category: SpotCategory.restaurant,
      latitude: 35.665486,
      longitude: 139.770667,
      address: '東京都中央区築地4-13-5',
      description: '市場直送の新鮮な海鮮丼や握り寿司を堪能できる和食レストラン。',
      rating: 4.8,
    ),
  ];

  @override
  Future<List<MapSpot>> getSpots() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return sampleSpots;
  }

  @override
  Future<MapSpot?> getSpotById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return sampleSpots.where((spot) => spot.id == id).firstOrNull;
  }
}

/// SpotRepository の Provider
@riverpod
SpotRepository spotRepository(Ref ref) {
  return SpotRepositoryImpl();
}
