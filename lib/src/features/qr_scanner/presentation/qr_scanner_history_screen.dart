import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_history_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scan_history_model.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scan_result_sheet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// QRコードスキャン履歴画面
class QrScannerHistoryScreen extends ConsumerWidget {
  /// コンストラクタ
  const QrScannerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(qrScannerHistoryControllerProvider);
    final historyNotifier = ref.read(
      qrScannerHistoryControllerProvider.notifier,
    );
    final urlService = ref.watch(urlLauncherServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrScannerHistoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: l10n.qrScannerDeleteAll,
            onPressed: historyAsync.maybeWhen(
              data: (list) => list.isEmpty
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.qrScannerDeleteAll),
                          content: Text(l10n.qrScannerDeleteAllConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                l10n.delete,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await historyNotifier.deleteAllHistories();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.qrScannerDeleteAllSuccess),
                            ),
                          );
                        }
                      }
                    },
              orElse: () => null,
            ),
          ),
        ],
      ),
      body: switch (historyAsync) {
        AsyncData(:final value) =>
          value.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.qrScannerHistoryEmpty,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = value[index];
                    return _HistoryListTile(
                      item: item,
                      isUrl: urlService.isWebUrl(item.rawValue),
                      onTap: () =>
                          QrScanResultSheet.show(context, item.rawValue),
                      onConfirmDismiss: () async {
                        try {
                          await historyNotifier.deleteHistory(item.id);
                          return true;
                        } on Exception catch (e, st) {
                          ref
                              .read(loggerProvider)
                              .error('Failed to delete history item: $e\n$st');
                          return false;
                        }
                      },
                      onDismissed: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.qrScannerDeleteSuccess),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({
    required this.item,
    required this.isUrl,
    required this.onTap,
    required this.onConfirmDismiss,
    required this.onDismissed,
  });

  final QrScanHistoryModel item;
  final bool isUrl;
  final VoidCallback onTap;
  final Future<bool> Function() onConfirmDismiss;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => onConfirmDismiss(),
      onDismissed: (_) => onDismissed(),
      child: ListTile(
        leading: Icon(
          isUrl ? Icons.link : Icons.qr_code,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          item.rawValue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(dateFormat.format(item.scannedAt)),
        onTap: onTap,
      ),
    );
  }
}
