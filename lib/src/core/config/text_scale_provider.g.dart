// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_scale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🔍 アプリ全体の文字サイズ倍率を管理・永続化するプロバイダー

@ProviderFor(TextScaleNotifier)
final textScaleProvider = TextScaleNotifierProvider._();

/// 🔍 アプリ全体の文字サイズ倍率を管理・永続化するプロバイダー
final class TextScaleNotifierProvider
    extends $AsyncNotifierProvider<TextScaleNotifier, AppTextScale> {
  /// 🔍 アプリ全体の文字サイズ倍率を管理・永続化するプロバイダー
  TextScaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textScaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textScaleNotifierHash();

  @$internal
  @override
  TextScaleNotifier create() => TextScaleNotifier();
}

String _$textScaleNotifierHash() => r'd61951ee9822fadbf05311ddab45142c0e62a543';

/// 🔍 アプリ全体の文字サイズ倍率を管理・永続化するプロバイダー

abstract class _$TextScaleNotifier extends $AsyncNotifier<AppTextScale> {
  FutureOr<AppTextScale> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppTextScale>, AppTextScale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppTextScale>, AppTextScale>,
              AsyncValue<AppTextScale>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
