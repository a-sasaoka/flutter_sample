/// 地図機能全体で利用する定数定義クラス
abstract final class MapConstants {
  /// Googleマップのホスト名
  static const googleMapsHost = 'www.google.com';

  /// Googleマップのルート案内（Directions）パス
  static const googleMapsDirectionsPath = '/maps/dir/';

  /// Google Maps Universal URL APIのバージョン番号（固定値: 1）
  static const googleMapsApiVersion = '1';

  /// Google Maps URL APIのパラメータ名: api
  static const googleMapsParamApi = 'api';

  /// Google Maps URL APIのパラメータ名: origin
  static const googleMapsParamOrigin = 'origin';

  /// Google Maps URL APIのパラメータ名: destination
  static const googleMapsParamDestination = 'destination';

  /// Google Maps URL APIのパラメータ名: travelmode
  static const googleMapsParamTravelMode = 'travelmode';

  /// Google Maps URL APIの公共交通機関モード値
  static const googleMapsTravelModeTransit = 'transit';
}
