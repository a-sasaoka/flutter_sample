part of '../app_router.dart';

/// 利用規約画面のルート
@TypedGoRoute<TermsRoute>(path: '/terms')
class TermsRoute extends GoRouteData with $TermsRoute {
  /// コンストラクタ
  const TermsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LegalDocumentScreen(type: LegalDocumentType.termsOfService);
  }
}

/// プライバシーポリシー画面のルート
@TypedGoRoute<PrivacyPolicyRoute>(path: '/privacy')
class PrivacyPolicyRoute extends GoRouteData with $PrivacyPolicyRoute {
  /// コンストラクタ
  const PrivacyPolicyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LegalDocumentScreen(type: LegalDocumentType.privacyPolicy);
  }
}
