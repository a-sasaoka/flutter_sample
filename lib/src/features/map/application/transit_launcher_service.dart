import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/map/domain/map_constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

part 'transit_launcher_service.g.dart';

/// 公共交通機関（TRANSIT）ルートのGoogleマップ連携を担当するサービスクラス
class TransitLauncherService {
  /// コンストラクタ
  const TransitLauncherService({
    required AppLockService appLockService,
    required Talker logger,
  }) : _appLockService = appLockService,
       _logger = logger;

  final AppLockService _appLockService;
  final Talker _logger;

  /// Googleマップの乗換案内Universal URLを生成する
  ///
  /// 公式ドキュメント仕様:
  /// `https://www.google.com/maps/dir/?api=1&origin=LAT,LNG&destination=LAT,LNG&travelmode=transit`
  /// 目的地名称（[destinationName]）が指定されている場合は、名称を優先指定します。
  Uri buildGoogleMapsTransitUri({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
  }) {
    final destinationParam =
        (destinationName != null && destinationName.trim().isNotEmpty)
        ? destinationName.trim()
        : '${destination.latitude},${destination.longitude}';

    return Uri.https(
      MapConstants.googleMapsHost,
      MapConstants.googleMapsDirectionsPath,
      <String, String>{
        MapConstants.googleMapsParamApi: MapConstants.googleMapsApiVersion,
        MapConstants.googleMapsParamOrigin:
            '${origin.latitude},${origin.longitude}',
        MapConstants.googleMapsParamDestination: destinationParam,
        MapConstants.googleMapsParamTravelMode:
            MapConstants.googleMapsTravelModeTransit,
      },
    );
  }

  /// 公共交通機関ルートの乗換案内を公式Googleマップ（または外部ブラウザ）で起動する
  ///
  /// アプリ復帰時の誤ロックを防ぐため、[AppLockService.runWithLockSuppression] で保護します。
  Future<bool> launchTransitRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
  }) async {
    final uri = buildGoogleMapsTransitUri(
      origin: origin,
      destination: destination,
      destinationName: destinationName,
    );

    return await _appLockService.runWithLockSuppression<bool>(() async {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _logger.warning('Failed to launch Google Maps URL: $uri');
        }
        return launched;
      } on Exception catch (e, st) {
        _logger.handle(e, st, 'Exception occurred while launching Google Maps');
        return false;
      }
    });
  }
}

/// [TransitLauncherService] を提供する Riverpod プロバイダー
@riverpod
TransitLauncherService transitLauncherService(Ref ref) {
  return TransitLauncherService(
    appLockService: ref.watch(appLockServiceProvider.notifier),
    logger: ref.watch(loggerProvider),
  );
}
