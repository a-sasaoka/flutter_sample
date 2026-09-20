// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_scanner_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// QRコードリーダーのロジックと状態を管理するコントローラー

@ProviderFor(QrScannerController)
final qrScannerControllerProvider = QrScannerControllerProvider._();

/// QRコードリーダーのロジックと状態を管理するコントローラー
final class QrScannerControllerProvider
    extends $NotifierProvider<QrScannerController, QrScannerState> {
  /// QRコードリーダーのロジックと状態を管理するコントローラー
  QrScannerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrScannerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrScannerControllerHash();

  @$internal
  @override
  QrScannerController create() => QrScannerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrScannerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrScannerState>(value),
    );
  }
}

String _$qrScannerControllerHash() =>
    r'7e85b950c4efe19fcba37633fca4daf7ad652cc9';

/// QRコードリーダーのロジックと状態を管理するコントローラー

abstract class _$QrScannerController extends $Notifier<QrScannerState> {
  QrScannerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QrScannerState, QrScannerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QrScannerState, QrScannerState>,
              QrScannerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
