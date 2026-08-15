/// 移動手段の種別を表す列挙型
enum TravelMode {
  /// 車 (自動車)
  driving('DRIVE'),

  /// 徒歩
  walking('WALK'),

  /// 自転車
  bicycling('BICYCLE'),

  /// 公共交通機関 (電車・バス等)
  transit('TRANSIT');

  /// コンストラクタ
  const TravelMode(this.apiValue);

  /// Google Routes API に渡す travelMode パラメータ値
  final String apiValue;
}
