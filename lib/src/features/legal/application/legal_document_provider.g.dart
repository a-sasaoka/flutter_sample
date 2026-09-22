// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_document_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AssetBundle を提供するプロバイダー（単体テスト時にモック可能）

@ProviderFor(assetBundle)
final assetBundleProvider = AssetBundleProvider._();

/// AssetBundle を提供するプロバイダー（単体テスト時にモック可能）

final class AssetBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// AssetBundle を提供するプロバイダー（単体テスト時にモック可能）
  AssetBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assetBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assetBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return assetBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$assetBundleHash() => r'5cea0c52c8a37a89f5db259f74012754217cb897';

/// 法的ドキュメントのMarkdownテキストを取得するプロバイダー

@ProviderFor(legalDocument)
final legalDocumentProvider = LegalDocumentFamily._();

/// 法的ドキュメントのMarkdownテキストを取得するプロバイダー

final class LegalDocumentProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 法的ドキュメントのMarkdownテキストを取得するプロバイダー
  LegalDocumentProvider._({
    required LegalDocumentFamily super.from,
    required LegalDocumentType super.argument,
  }) : super(
         retry: null,
         name: r'legalDocumentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$legalDocumentHash();

  @override
  String toString() {
    return r'legalDocumentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as LegalDocumentType;
    return legalDocument(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LegalDocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$legalDocumentHash() => r'b139d93fb74bfb9e5c4815fa7e124deed42c4dc0';

/// 法的ドキュメントのMarkdownテキストを取得するプロバイダー

final class LegalDocumentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, LegalDocumentType> {
  LegalDocumentFamily._()
    : super(
        retry: null,
        name: r'legalDocumentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 法的ドキュメントのMarkdownテキストを取得するプロバイダー

  LegalDocumentProvider call(LegalDocumentType type) =>
      LegalDocumentProvider._(argument: type, from: this);

  @override
  String toString() => r'legalDocumentProvider';
}
