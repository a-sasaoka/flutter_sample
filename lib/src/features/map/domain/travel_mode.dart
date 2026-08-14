/// 移動手段の種別を表す列挙型
enum TravelMode {
  /// 車 (自動車)
  driving('driving'),

  /// 徒歩
  walking('walking'),

  /// 自転車
  bicycling('bicycling'),

  /// 公共交通機関 (電車・バス等)
  transit('transit');

  /// コンストラクタ
  const TravelMode(this.apiValue);

  /// Google Directions API に渡す mode パラメータ値
  final String apiValue;
}
