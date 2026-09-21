import 'package:flutter/services.dart';
import 'package:flutter_sample/src/features/legal/domain/legal_document_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'legal_document_provider.g.dart';

/// AssetBundle を提供するプロバイダー（単体テスト時にモック可能）
@riverpod
AssetBundle assetBundle(Ref ref) {
  return rootBundle;
}

/// 法的ドキュメントのMarkdownテキストを取得するプロバイダー
@riverpod
Future<String> legalDocument(Ref ref, LegalDocumentType type) {
  final bundle = ref.watch(assetBundleProvider);
  return bundle.loadString(type.assetPath);
}
