import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/application/secure_storage_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/application/shared_preferences_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 開発者向けストレージ確認・編集画面
class DeveloperStorageScreen extends HookConsumerWidget {
  /// コンストラクタ
  const DeveloperStorageScreen({
    this.initialTabIndex = 0,
    super.key,
  });

  /// 初期表示するタブのインデックス
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 本番環境ガード
    final currentFlavor = ref.watch(flavorProvider);
    if (currentFlavor == Flavor.prod) {
      var path = '/dev-tools/storage';
      try {
        path = GoRouterState.of(context).uri.path;
      } on Object catch (_) {
        // GoRouter コンテキスト外（テストなど）の場合はデフォルトパスを使用
      }
      return NotFoundScreen(unknownPath: path);
    }

    final tabController = useTabController(
      initialLength: 2,
      initialIndex: initialTabIndex,
    );
    final l10n = context.l10n;

    // データ監視
    final prefsState = ref.watch(sharedPreferencesItemsProvider);
    final secureState = ref.watch(secureStorageItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devStorageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: l10n.devStorageClearAll,
            onPressed: () async {
              await _showClearConfirmDialog(context, ref, tabController.index);
            },
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: l10n.devStoragePrefsTab),
            Tab(text: l10n.devStorageSecureTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // SharedPreferences タブ
          prefsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text(l10n.devStorageError(err.toString()))),
            data: (data) => _SharedPreferencesTab(data: data),
          ),
          // SecureStorage タブ
          secureState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text(l10n.devStorageError(err.toString()))),
            data: (data) => _SecureStorageTab(data: data),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context, ref, tabController.index);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 一括削除の確認ダイアログを表示
  Future<void> _showClearConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    int tabIndex,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.devStorageClearAll),
        content: Text(l10n.devStorageConfirmClear),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (tabIndex == 0) {
        await ref.read(sharedPreferencesItemsProvider.notifier).clear();
      } else {
        await ref.read(secureStorageItemsProvider.notifier).clear();
      }
    }
  }

  /// 新規追加ダイアログを表示
  void _showAddDialog(BuildContext context, WidgetRef ref, int tabIndex) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) =>
            tabIndex == 0 ? const _AddPrefsDialog() : const _AddSecureDialog(),
      ),
    );
  }
}

/// SharedPreferencesの一覧と操作を行うウィジェット
class _SharedPreferencesTab extends ConsumerWidget {
  const _SharedPreferencesTab({required this.data});

  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (data.isEmpty) {
      return Center(
        child: Text(l10n.devStorageNoPrefsData),
      );
    }

    final sortedKeys = data.keys.toList()..sort();

    return ListView.separated(
      itemCount: sortedKeys.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final value = data[key];
        final type = value.runtimeType.toString();

        return ListTile(
          title: Text(
            key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            value.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref
                      .read(sharedPreferencesItemsProvider.notifier)
                      .remove(key);
                },
              ),
            ],
          ),
          onTap: () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (context) => _EditPrefsDialog(
                  storageKey: key,
                  currentValue: value,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// SecureStorageの一覧と操作を行うウィジェット
class _SecureStorageTab extends ConsumerWidget {
  const _SecureStorageTab({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (data.isEmpty) {
      return Center(
        child: Text(l10n.devStorageNoSecureData),
      );
    }

    final sortedKeys = data.keys.toList()..sort();

    return ListView.separated(
      itemCount: sortedKeys.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final value = data[key];

        return ListTile(
          title: Text(
            key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            value ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref.read(secureStorageItemsProvider.notifier).remove(key);
            },
          ),
          onTap: () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (context) => _EditSecureDialog(
                  storageKey: key,
                  currentValue: value ?? '',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _StorageType {
  stringType('String'),
  intType('int'),
  doubleType('double'),
  boolType('bool');

  const _StorageType(this.label);
  final String label;
}

/// SharedPreferencesの新規追加ダイアログ
class _AddPrefsDialog extends HookConsumerWidget {
  const _AddPrefsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keyController = useTextEditingController();
    final valController = useTextEditingController();
    final selectedType = useState<_StorageType>(_StorageType.stringType);
    final boolValue = useState<bool>(false);

    return AlertDialog(
      title: Text(l10n.devStorageAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: l10n.devStorageKey,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<_StorageType>(
              initialValue: selectedType.value,
              decoration: InputDecoration(
                labelText: l10n.devStorageType,
              ),
              items: _StorageType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  selectedType.value = val;
                }
              },
            ),
            const SizedBox(height: 16),
            if (selectedType.value == _StorageType.boolType)
              SwitchListTile(
                title: Text(l10n.devStorageValue),
                value: boolValue.value,
                onChanged: (val) {
                  boolValue.value = val;
                },
              )
            else
              TextField(
                controller: valController,
                decoration: InputDecoration(
                  labelText: l10n.devStorageValue,
                ),
                keyboardType:
                    selectedType.value == _StorageType.intType ||
                        selectedType.value == _StorageType.doubleType
                    ? TextInputType.number
                    : TextInputType.text,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () async {
            final key = keyController.text.trim();
            if (key.isEmpty) return;

            Object? val;
            switch (selectedType.value) {
              case _StorageType.stringType:
                val = valController.text;
              case _StorageType.intType:
                val = int.tryParse(valController.text) ?? 0;
              case _StorageType.doubleType:
                val = double.tryParse(valController.text) ?? 0.0;
              case _StorageType.boolType:
                val = boolValue.value;
            }

            if (context.mounted) {
              await ref
                  .read(sharedPreferencesItemsProvider.notifier)
                  .set(key, val);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

/// SharedPreferencesの編集ダイアログ
class _EditPrefsDialog extends HookConsumerWidget {
  const _EditPrefsDialog({
    required this.storageKey,
    required this.currentValue,
  });

  final String storageKey;
  final Object? currentValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final valController = useTextEditingController(
      text: currentValue is bool ? '' : currentValue?.toString() ?? '',
    );
    final boolValue = useState<bool>(currentValue == true);

    return AlertDialog(
      title: Text(l10n.devStorageEditDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.devStorageKey}: $storageKey',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (currentValue is bool)
              SwitchListTile(
                title: Text(l10n.devStorageValue),
                value: boolValue.value,
                onChanged: (val) {
                  boolValue.value = val;
                },
              )
            else
              TextField(
                controller: valController,
                decoration: InputDecoration(
                  labelText: l10n.devStorageValue,
                ),
                keyboardType: currentValue is num
                    ? TextInputType.number
                    : TextInputType.text,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () async {
            Object? val;
            if (currentValue is bool) {
              val = boolValue.value;
            } else if (currentValue is int) {
              val = int.tryParse(valController.text) ?? currentValue;
            } else if (currentValue is double) {
              val = double.tryParse(valController.text) ?? currentValue;
            } else {
              val = valController.text;
            }

            if (val != null && context.mounted) {
              await ref
                  .read(sharedPreferencesItemsProvider.notifier)
                  .set(storageKey, val);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

/// SecureStorageの新規追加ダイアログ
class _AddSecureDialog extends HookConsumerWidget {
  const _AddSecureDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keyController = useTextEditingController();
    final valController = useTextEditingController();

    return AlertDialog(
      title: Text(l10n.devStorageAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: l10n.devStorageKey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valController,
              decoration: InputDecoration(
                labelText: l10n.devStorageValue,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () async {
            final key = keyController.text.trim();
            final val = valController.text;
            if (key.isEmpty) return;

            if (context.mounted) {
              await ref.read(secureStorageItemsProvider.notifier).set(key, val);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

/// SecureStorageの編集ダイアログ
class _EditSecureDialog extends HookConsumerWidget {
  const _EditSecureDialog({
    required this.storageKey,
    required this.currentValue,
  });

  final String storageKey;
  final String currentValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final valController = useTextEditingController(text: currentValue);

    return AlertDialog(
      title: Text(l10n.devStorageEditDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.devStorageKey}: $storageKey',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valController,
              decoration: InputDecoration(
                labelText: l10n.devStorageValue,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () async {
            final val = valController.text;
            if (context.mounted) {
              await ref
                  .read(secureStorageItemsProvider.notifier)
                  .set(storageKey, val);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
