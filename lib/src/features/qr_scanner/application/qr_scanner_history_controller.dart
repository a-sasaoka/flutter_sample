import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scan_history_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'qr_scanner_history_controller.g.dart';

/// QRコードスキャン履歴一覧の状態管理と操作を行うコントローラー
@riverpod
class QrScannerHistoryController extends _$QrScannerHistoryController {
  @override
  Stream<List<QrScanHistoryModel>> build() {
    final dao = ref.watch(qrScanHistoriesDaoProvider);
    return dao.watchAllHistories().map(
      (histories) => histories.map((h) => h.toModel()).toList(),
    );
  }

  /// 指定したIDの履歴を1件削除します
  Future<void> deleteHistory(int id) async {
    final dao = ref.read(qrScanHistoriesDaoProvider);
    await dao.deleteHistory(id);
  }

  /// すべてのスキャン履歴を一括削除します
  Future<void> deleteAllHistories() async {
    final dao = ref.read(qrScanHistoriesDaoProvider);
    await dao.deleteAllHistories();
  }
}
