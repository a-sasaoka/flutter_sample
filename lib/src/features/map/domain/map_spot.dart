import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'map_spot.freezed.dart';

/// 📍 スポットカテゴリ
enum SpotCategory {
  /// カフェ
  cafe,

  /// 公園
  park,

  /// レストラン
  restaurant,

  /// 観光地
  sightseeing,

  /// ショッピング
  shopping,

  /// その他
  other,
}

/// 📍 SpotCategory の拡張機能
extension SpotCategoryX on SpotCategory {
  /// カテゴリの表示名を取得
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case SpotCategory.cafe:
        return l10n.mapSpotCategoryCafe;
      case SpotCategory.park:
        return l10n.mapSpotCategoryPark;
      case SpotCategory.restaurant:
        return l10n.mapSpotCategoryRestaurant;
      case SpotCategory.sightseeing:
        return l10n.mapSpotCategorySightseeing;
      case SpotCategory.shopping:
        return l10n.mapSpotCategoryShopping;
      case SpotCategory.other:
        return l10n.mapSpotCategoryOther;
    }
  }

  /// カテゴリに対応するアイコンを取得
  IconData get icon {
    switch (this) {
      case SpotCategory.cafe:
        return Icons.local_cafe;
      case SpotCategory.park:
        return Icons.park;
      case SpotCategory.restaurant:
        return Icons.restaurant;
      case SpotCategory.sightseeing:
        return Icons.photo_camera;
      case SpotCategory.shopping:
        return Icons.shopping_bag;
      case SpotCategory.other:
        return Icons.place;
    }
  }

  /// カテゴリに対応するカラーを取得
  Color get color {
    switch (this) {
      case SpotCategory.cafe:
        return Colors.amber;
      case SpotCategory.park:
        return Colors.green;
      case SpotCategory.restaurant:
        return Colors.deepOrange;
      case SpotCategory.sightseeing:
        return Colors.purple;
      case SpotCategory.shopping:
        return Colors.blue;
      case SpotCategory.other:
        return Colors.red;
    }
  }

  /// GoogleMap の Marker 色の Hue 値を取得
  double get markerHue {
    switch (this) {
      case SpotCategory.cafe:
        return BitmapDescriptor.hueOrange;
      case SpotCategory.park:
        return BitmapDescriptor.hueGreen;
      case SpotCategory.restaurant:
        return BitmapDescriptor.hueRose;
      case SpotCategory.sightseeing:
        return BitmapDescriptor.hueViolet;
      case SpotCategory.shopping:
        return BitmapDescriptor.hueAzure;
      case SpotCategory.other:
        return BitmapDescriptor.hueRed;
    }
  }
}

/// 🗺️ 地図上にプロットするスポット（施設・ピン）のドメインモデル
@freezed
abstract class MapSpot with _$MapSpot {
  /// コンストラクタ
  const factory MapSpot({
    /// スポット ID
    required String id,

    /// スポット名称
    required String name,

    /// カテゴリ
    required SpotCategory category,

    /// 緯度
    required double latitude,

    /// 経度
    required double longitude,

    /// 住所
    String? address,

    /// スポット説明
    String? description,

    /// 評価 (0.0 - 5.0)
    double? rating,
  }) = _MapSpot;
}
