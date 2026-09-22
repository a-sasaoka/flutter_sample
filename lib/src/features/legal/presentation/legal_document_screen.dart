import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/features/legal/application/legal_document_provider.dart';
import 'package:flutter_sample/src/features/legal/domain/legal_document_type.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 利用規約・プライバシーポリシー閲覧画面
class LegalDocumentScreen extends ConsumerWidget {
  /// コンストラクタ
  const LegalDocumentScreen({required this.type, super.key});

  /// 表示するドキュメント種別
  final LegalDocumentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = switch (type) {
      LegalDocumentType.termsOfService => l10n.termsOfServiceTitle,
      LegalDocumentType.privacyPolicy => l10n.privacyPolicyTitle,
    };

    final documentAsync = ref.watch(legalDocumentProvider(type));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (documentAsync) {
        AsyncData(:final value) => Markdown(
          data: value,
          selectable: true,
          onTapLink: (text, href, title) async {
            if (href == null) return;
            final success = await ref
                .read(urlLauncherServiceProvider)
                .openUrl(href);
            if (!success && context.mounted) {
              context.showErrorSnackBar(l10n.legalOpenUrlFailed);
            }
          },
        ),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.legalLoadError,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(legalDocumentProvider(type)),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
