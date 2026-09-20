// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_scanner_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// QRコードスキャン履歴一覧の状態管理と操作を行うコントローラー

@ProviderFor(QrScannerHistoryController)
final qrScannerHistoryControllerProvider =
    QrScannerHistoryControllerProvider._();

/// QRコードスキャン履歴一覧の状態管理と操作を行うコントローラー
final class QrScannerHistoryControllerProvider
    extends
        $StreamNotifierProvider<
          QrScannerHistoryController,
          List<QrScanHistoryModel>
        > {
  /// QRコードスキャン履歴一覧の状態管理と操作を行うコントローラー
  QrScannerHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrScannerHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrScannerHistoryControllerHash();

  @$internal
  @override
  QrScannerHistoryController create() => QrScannerHistoryController();
}

String _$qrScannerHistoryControllerHash() =>
    r'd19638c15d68ae1443bc03d47b80978357df4b6b';

/// QRコードスキャン履歴一覧の状態管理と操作を行うコントローラー

abstract class _$QrScannerHistoryController
    extends $StreamNotifier<List<QrScanHistoryModel>> {
  Stream<List<QrScanHistoryModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<QrScanHistoryModel>>,
              List<QrScanHistoryModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<QrScanHistoryModel>>,
                List<QrScanHistoryModel>
              >,
              AsyncValue<List<QrScanHistoryModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
