// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_time_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 現在の日時を提供するプロバイダー
/// テスト時にはこのプロバイダーを override することで、任意の日時でテストが可能になります。

@ProviderFor(currentDateTime)
final currentDateTimeProvider = CurrentDateTimeProvider._();

/// 現在の日時を提供するプロバイダー
/// テスト時にはこのプロバイダーを override することで、任意の日時でテストが可能になります。

final class CurrentDateTimeProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// 現在の日時を提供するプロバイダー
  /// テスト時にはこのプロバイダーを override することで、任意の日時でテストが可能になります。
  CurrentDateTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDateTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDateTimeHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return currentDateTime(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$currentDateTimeHash() => r'6f5fa7406d578f6c9ede8b55b8c08ea9c7d92b9d';
