import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 🔔 Push通知・ディープリンク検証画面（開発者ツール）
class PushNotificationDemoScreen extends HookConsumerWidget {
  /// コンストラクタ
  const PushNotificationDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devNotificationTitle),
      ),
      body: switch (notificationState) {
        NotificationStateLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        NotificationStateError(:final message) => Center(
          child: Text(message),
        ),
        NotificationStateData(
          :final fcmToken,
          :final authorizationStatus,
          :final latestPayload,
        ) =>
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. FCM トークン表示・コピーカード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vpn_key_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.devNotificationTokenLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        fcmToken ?? l10n.devNotificationTokenNotObtained,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: fcmToken == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: fcmToken),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.devNotificationTokenCopied,
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(l10n.devNotificationTokenCopy),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 通知権限ステータスカード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.devNotificationPermissionLabel(
                                _getPermissionStatusText(
                                  l10n,
                                  authorizationStatus,
                                ),
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          unawaited(
                            ref
                                .read(notificationProvider.notifier)
                                .requestPermission(),
                          );
                        },
                        icon: const Icon(Icons.security_rounded),
                        label: Text(l10n.devNotificationRequestPermission),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. テスト通知発火（ディープリンク検証）カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.send_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.devNotificationTestSection,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // AI チャット通知テスト
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded),
                        title: Text(l10n.devNotificationTestChatTitle),
                        subtitle: Text(l10n.devNotificationTestChatBody),
                        trailing: IconButton.filledTonal(
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(notificationProvider.notifier)
                                  .sendTestNotification(
                                    NotificationPayload(
                                      path: '/chat',
                                      title: l10n.devNotificationTestChatTitle,
                                      body: l10n.devNotificationTestChatBody,
                                    ),
                                  ),
                            );
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ),
                      const Divider(),

                      // メモ一覧通知テスト
                      ListTile(
                        leading: const Icon(Icons.note_alt_outlined),
                        title: Text(l10n.devNotificationTestMemoTitle),
                        subtitle: Text(l10n.devNotificationTestMemoBody),
                        trailing: IconButton.filledTonal(
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(notificationProvider.notifier)
                                  .sendTestNotification(
                                    NotificationPayload(
                                      path: '/memos',
                                      title: l10n.devNotificationTestMemoTitle,
                                      body: l10n.devNotificationTestMemoBody,
                                    ),
                                  ),
                            );
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ),
                      const Divider(),

                      // プロフィール通知テスト
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(l10n.devNotificationTestProfileTitle),
                        subtitle: Text(l10n.devNotificationTestProfileBody),
                        trailing: IconButton.filledTonal(
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(notificationProvider.notifier)
                                  .sendTestNotification(
                                    NotificationPayload(
                                      path: '/settings',
                                      title:
                                          l10n.devNotificationTestProfileTitle,
                                      body: l10n.devNotificationTestProfileBody,
                                    ),
                                  ),
                            );
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. 最新タップペイロード表示
              if (latestPayload != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.devNotificationLatestPayloadLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          latestPayload.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
      },
    );
  }

  String _getPermissionStatusText(
    AppLocalizations l10n,
    AuthorizationStatus? status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized => l10n.devNotificationStatusAuthorized,
      AuthorizationStatus.denied => l10n.devNotificationStatusDenied,
      AuthorizationStatus.provisional => l10n.devNotificationStatusProvisional,
      _ => l10n.devNotificationStatusNotDetermined,
    };
  }
}
