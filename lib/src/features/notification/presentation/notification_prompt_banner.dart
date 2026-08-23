import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🔔 ホーム画面等で通知が未許可のユーザーに案内・許可を促すバナー
class NotificationPromptBanner extends HookConsumerWidget {
  /// コンストラクタ
  const NotificationPromptBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = useState(false);
    final notificationState = ref.watch(notificationProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 閉じるボタンが押された場合は非表示
    if (isDismissed.value) {
      return const SizedBox.shrink();
    }

    // 通知状態に応じた判定
    if (notificationState case final NotificationStateData data) {
      final status = data.authorizationStatus;
      // 許可済み（または仮許可）の場合は表示しない
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        return const SizedBox.shrink();
      }

      final isDenied = status == AuthorizationStatus.denied;

      final title = l10n.notificationBannerTitle;
      final body = l10n.notificationBannerBody;
      final enableText = l10n.notificationBannerEnableButton;
      final settingsText = l10n.notificationBannerSettingsButton;
      final dismissTooltip = l10n.notificationBannerDismiss;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: dismissTooltip,
                    onPressed: () => isDismissed.value = true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: isDenied
                    ? FilledButton.tonalIcon(
                        onPressed: () {
                          unawaited(
                            AppSettings.openAppSettings(
                              type: AppSettingsType.notification,
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: Text(settingsText),
                      )
                    : FilledButton.icon(
                        onPressed: () {
                          unawaited(
                            ref
                                .read(notificationProvider.notifier)
                                .requestPermission(),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 16,
                        ),
                        label: Text(enableText),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
