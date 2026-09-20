// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_scan_histories_dao.dart';

// ignore_for_file: type=lint
mixin _$QrScanHistoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $QrScanHistoriesTable get qrScanHistories => attachedDatabase.qrScanHistories;
  QrScanHistoriesDaoManager get managers => QrScanHistoriesDaoManager(this);
}

class QrScanHistoriesDaoManager {
  final _$QrScanHistoriesDaoMixin _db;
  QrScanHistoriesDaoManager(this._db);
  $$QrScanHistoriesTableTableManager get qrScanHistories =>
      $$QrScanHistoriesTableTableManager(
        _db.attachedDatabase,
        _db.qrScanHistories,
      );
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [QrScanHistoriesDao] を提供するプロバイダー

@ProviderFor(qrScanHistoriesDao)
final qrScanHistoriesDaoProvider = QrScanHistoriesDaoProvider._();

/// [QrScanHistoriesDao] を提供するプロバイダー

final class QrScanHistoriesDaoProvider
    extends
        $FunctionalProvider<
          QrScanHistoriesDao,
          QrScanHistoriesDao,
          QrScanHistoriesDao
        >
    with $Provider<QrScanHistoriesDao> {
  /// [QrScanHistoriesDao] を提供するプロバイダー
  QrScanHistoriesDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrScanHistoriesDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrScanHistoriesDaoHash();

  @$internal
  @override
  $ProviderElement<QrScanHistoriesDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QrScanHistoriesDao create(Ref ref) {
    return qrScanHistoriesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrScanHistoriesDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrScanHistoriesDao>(value),
    );
  }
}

String _$qrScanHistoriesDaoHash() =>
    r'7eed214b64e0e7600b04a0db2f62fe4865a84cd3';
