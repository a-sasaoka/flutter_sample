import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// QRコードスキャン結果を表示するボトムシート
class QrScanResultSheet extends ConsumerWidget {
  /// コンストラクタ
  const QrScanResultSheet({required this.rawValue, super.key});

  /// スキャンした文字列
  final String rawValue;

  /// ボトムシートを表示する静的メソッド
  static Future<void> show(BuildContext context, String rawValue) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => QrScanResultSheet(rawValue: rawValue),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final urlService = ref.watch(urlLauncherServiceProvider);
    final isUrl = urlService.isWebUrl(rawValue);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ハンドルバー
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // タイトル
            Row(
              children: [
                Icon(
                  isUrl ? Icons.link : Icons.qr_code_2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.qrScannerResultTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // スキャン結果テキスト
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  rawValue,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // アクションボタン
            if (isUrl) ...[
              FilledButton.icon(
                onPressed: () async {
                  var success = false;
                  try {
                    success = await urlService.openUrl(rawValue);
                  } on Exception catch (e, st) {
                    ref
                        .read(loggerProvider)
                        .error('Failed to open URL: $e\n$st');
                  }
                  if (!context.mounted) return;
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.qrScannerFailedToOpenUrl)),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: Text(l10n.qrScannerOpenUrl),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: rawValue));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.qrScannerCopied)));
              },
              icon: const Icon(Icons.copy),
              label: Text(l10n.qrScannerCopy),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.qrScannerRescan),
            ),
          ],
        ),
      ),
    );
  }
}
