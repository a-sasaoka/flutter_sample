// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリ全体のロケールを管理するプロバイダ

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// アプリ全体のロケールを管理するプロバイダ
final class LocaleNotifierProvider
    extends $AsyncNotifierProvider<LocaleNotifier, Locale?> {
  /// アプリ全体のロケールを管理するプロバイダ
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();
}

String _$localeNotifierHash() => r'0e4c204eeb3f70019157b1c19a4eb09f90c585c5';

/// アプリ全体のロケールを管理するプロバイダ

abstract class _$LocaleNotifier extends $AsyncNotifier<Locale?> {
  FutureOr<Locale?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Locale?>, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Locale?>, Locale?>,
              AsyncValue<Locale?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
