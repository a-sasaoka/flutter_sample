import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/features/legal/application/legal_document_provider.dart';
import 'package:flutter_sample/src/features/legal/domain/legal_document_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  group('assetBundleProvider', () {
    test('デフォルトで rootBundle を返すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bundle = container.read(assetBundleProvider);
      check(bundle).equals(rootBundle);
    });
  });

  group('legalDocumentProvider', () {
    late MockAssetBundle mockAssetBundle;

    setUp(() {
      mockAssetBundle = MockAssetBundle();
    });

    test('利用規約のMarkdownが正常に取得できること', () async {
      when(
        () => mockAssetBundle.loadString(
          LegalDocumentType.termsOfService.assetPath,
        ),
      ).thenAnswer((_) async => '# 利用規約');

      final container = ProviderContainer(
        overrides: [assetBundleProvider.overrideWithValue(mockAssetBundle)],
      );
      addTearDown(container.dispose);

      // AutoDisposeなプロバイダーをテストする際は、ロード中の予期せぬ破棄を防ぐため直前で listen
      final subscription = container.listen(
        legalDocumentProvider(LegalDocumentType.termsOfService),
        (_, _) {},
      );
      addTearDown(subscription.close);

      final result = await container.read(
        legalDocumentProvider(LegalDocumentType.termsOfService).future,
      );

      check(result).equals('# 利用規約');
      verify(
        () => mockAssetBundle.loadString(
          LegalDocumentType.termsOfService.assetPath,
        ),
      ).called(1);
    });

    test('プライバシーポリシーのMarkdownが正常に取得できること', () async {
      when(
        () => mockAssetBundle.loadString(
          LegalDocumentType.privacyPolicy.assetPath,
        ),
      ).thenAnswer((_) async => '# プライバシーポリシー');

      final container = ProviderContainer(
        overrides: [assetBundleProvider.overrideWithValue(mockAssetBundle)],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        legalDocumentProvider(LegalDocumentType.privacyPolicy),
        (_, _) {},
      );
      addTearDown(subscription.close);

      final result = await container.read(
        legalDocumentProvider(LegalDocumentType.privacyPolicy).future,
      );

      check(result).equals('# プライバシーポリシー');
      verify(
        () => mockAssetBundle.loadString(
          LegalDocumentType.privacyPolicy.assetPath,
        ),
      ).called(1);
    });

    test('AssetBundleの読み込みに失敗した場合、AsyncErrorとなること', () async {
      final exception = Exception('Asset not found');
      when(
        () => mockAssetBundle.loadString(any()),
      ).thenAnswer((_) => Future.error(exception));

      final container = ProviderContainer(
        overrides: [assetBundleProvider.overrideWithValue(mockAssetBundle)],
      );
      addTearDown(container.dispose);

      // 非同期エラーのテスト: `.future` は使わずに状態の完了を待機する
      final subscription = container.listen(
        legalDocumentProvider(LegalDocumentType.termsOfService),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      final state = container.read(
        legalDocumentProvider(LegalDocumentType.termsOfService),
      );
      check(state.hasError).isTrue();
      check(state.error).equals(exception);
    });
  });
}
