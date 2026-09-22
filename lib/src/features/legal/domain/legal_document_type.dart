import 'package:flutter_sample/gen/assets.gen.dart';

/// 法的ドキュメントの種別
enum LegalDocumentType {
  /// 利用規約
  termsOfService,

  /// プライバシーポリシー
  privacyPolicy;

  /// アセットファイルのパス（flutter_gen による型安全な参照）
  String get assetPath => switch (this) {
    LegalDocumentType.termsOfService => Assets.markdown.termsOfService,
    LegalDocumentType.privacyPolicy => Assets.markdown.privacyPolicy,
  };
}
