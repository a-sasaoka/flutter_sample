// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_time_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 現在の日時を取得する関数を提供するプロバイダー
///
/// 以前の方式（DateTimeを直接返す）では、一度取得した値がキャッシュされてしまい
/// 時間が更新されない問題がありましたが、この方式（関数を返す）にすることで
/// 呼び出すたびに最新の時刻を取得できます。

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// 現在の日時を取得する関数を提供するプロバイダー
///
/// 以前の方式（DateTimeを直接返す）では、一度取得した値がキャッシュされてしまい
/// 時間が更新されない問題がありましたが、この方式（関数を返す）にすることで
/// 呼び出すたびに最新の時刻を取得できます。

final class ClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// 現在の日時を取得する関数を提供するプロバイダー
  ///
  /// 以前の方式（DateTimeを直接返す）では、一度取得した値がキャッシュされてしまい
  /// 時間が更新されない問題がありましたが、この方式（関数を返す）にすることで
  /// 呼び出すたびに最新の時刻を取得できます。
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockHash() => r'c3e4569d7dfec1ffefaec061d2912433598ee599';
