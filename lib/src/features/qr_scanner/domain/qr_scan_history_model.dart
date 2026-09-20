import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_scan_history_model.freezed.dart';

/// QRコードスキャン履歴のドメインモデル（sealed クラス）
@freezed
sealed class QrScanHistoryModel with _$QrScanHistoryModel {
  /// コンストラクタ
  const factory QrScanHistoryModel({
    required int id,
    required String rawValue,
    required DateTime scannedAt,
  }) = _QrScanHistoryModel;
}

/// データベースモデルからドメインモデルへの変換拡張
extension QrScanHistoryToModelX on QrScanHistory {
  /// [QrScanHistoryModel] に変換します
  QrScanHistoryModel toModel() =>
      QrScanHistoryModel(id: id, rawValue: rawValue, scannedAt: scannedAt);
}
