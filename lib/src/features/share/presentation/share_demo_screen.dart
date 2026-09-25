import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/share/application/share_position_origin_extension.dart';
import 'package:flutter_sample/src/features/share/application/share_service.dart';
import 'package:flutter_sample/src/features/share/domain/share_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

/// SNSシェア機能の検証用デモ画面
class ShareDemoScreen extends HookConsumerWidget {
  /// コンストラクタ
  const ShareDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shareService = ref.watch(shareServiceProvider);
    final appLockService = ref.watch(appLockServiceProvider.notifier);
    final logger = ref.watch(loggerProvider);

    final textController = useTextEditingController(
      text: l10n.shareDefaultText,
    );
    final urlController = useTextEditingController(
      text: ShareConfig.defaultShareUrl,
    );
    final subjectController = useTextEditingController();
    final selectedImage = useState<XFile?>(null);

    void showSnackBar(String message) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    void handleShareResult(ShareResult result) {
      switch (result.status) {
        case ShareResultStatus.success:
          showSnackBar(l10n.shareSuccess);
        case ShareResultStatus.dismissed:
          showSnackBar(l10n.shareDismissed);
        case ShareResultStatus.unavailable:
          showSnackBar(l10n.shareUnavailable);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. テキスト・URL共有カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.shareTextSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('share_text_field'),
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: l10n.shareTextLabel,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('share_url_field'),
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n.shareUrlLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('share_subject_field'),
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: l10n.shareSubjectLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (btnContext) {
                      return FilledButton.icon(
                        key: const Key('share_text_button'),
                        onPressed: () async {
                          final text = textController.text.trim();
                          final url = urlController.text.trim();
                          final subject = subjectController.text.trim();

                          final combinedText = url.isNotEmpty
                              ? '$text $url'
                              : text;
                          if (combinedText.isEmpty) {
                            return;
                          }

                          final result = await shareService.shareText(
                            text: combinedText,
                            subject: subject.isNotEmpty ? subject : null,
                            sharePositionOrigin: btnContext.sharePositionOrigin,
                          );
                          handleShareResult(result);
                        },
                        icon: const Icon(Icons.share),
                        label: Text(l10n.shareExecuteButton),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. 画像共有カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.shareImageSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedImage.value case final image?) ...[
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(image.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              icon: const Icon(Icons.close),
                              tooltip: l10n.shareClearImage,
                              onPressed: () => selectedImage.value = null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.shareSelectedImage(image.name),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (btnContext) {
                        return FilledButton.icon(
                          key: const Key('share_selected_image_button'),
                          onPressed: () async {
                            final text = textController.text.trim();
                            final result = await shareService.shareXFiles(
                              files: [image],
                              text: text.isNotEmpty ? text : null,
                              sharePositionOrigin:
                                  btnContext.sharePositionOrigin,
                            );
                            handleShareResult(result);
                          },
                          icon: const Icon(Icons.share),
                          label: Text(l10n.shareExecuteButton),
                        );
                      },
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      key: const Key('pick_image_button'),
                      onPressed: () async {
                        final picked = await appLockService
                            .runWithLockSuppression<XFile?>(() async {
                              try {
                                final picker = ImagePicker();
                                return await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                              } on Object catch (e, stack) {
                                logger.warning(
                                  '⚠️ [ShareDemoScreen] Failed to pick image: '
                                  '$e',
                                  e,
                                  stack,
                                );
                                return null;
                              }
                            });
                        if (context.mounted && picked != null) {
                          selectedImage.value = picked;
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.sharePickImageButton),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Builder(
                    builder: (btnContext) {
                      return OutlinedButton.icon(
                        key: const Key('share_sample_image_button'),
                        onPressed: () async {
                          final origin = btnContext.sharePositionOrigin;
                          final sample = await shareService.createSampleImage();
                          final text = textController.text.trim();
                          final result = await shareService.shareXFiles(
                            files: [sample],
                            text: text.isNotEmpty ? text : null,
                            sharePositionOrigin: origin,
                          );
                          handleShareResult(result);
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.shareSampleImageButton),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 特定SNS直接共有カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.open_in_new_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.shareDirectSnsSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return FilledButton.icon(
                        key: const Key('share_x_button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                        onPressed: () async {
                          final text = textController.text.trim();
                          final url = urlController.text.trim();
                          final success = await shareService.shareToX(
                            text: text.isNotEmpty
                                ? text
                                : l10n.shareDefaultText,
                            url: url.isNotEmpty ? url : null,
                            hashtags: ShareConfig.defaultHashtags,
                          );
                          if (success) {
                            showSnackBar(l10n.shareDirectSuccess('X'));
                          } else {
                            showSnackBar(l10n.shareDirectFailed('X'));
                          }
                        },
                        icon: const Icon(Icons.send),
                        label: Text(l10n.shareToXButton),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('share_line_button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final text = textController.text.trim();
                      final url = urlController.text.trim();
                      final combined = url.isNotEmpty ? '$text $url' : text;
                      final success = await shareService.shareToLine(
                        text: combined.isNotEmpty
                            ? combined
                            : l10n.shareDefaultText,
                      );
                      if (success) {
                        showSnackBar(l10n.shareDirectSuccess('LINE'));
                      } else {
                        showSnackBar(l10n.shareDirectFailed('LINE'));
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.shareToLineButton),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
