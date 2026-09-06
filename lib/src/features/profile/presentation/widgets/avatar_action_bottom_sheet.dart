import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';

/// アバター変更メニューの選択肢
enum AvatarActionType {
  /// カメラで撮影
  camera,

  /// アルバムから選択
  gallery,

  /// 写真を削除
  delete,
}

/// アイコン写真の変更・削除を選択するボトムシートウィジェット
class AvatarActionBottomSheet extends StatelessWidget {
  /// コンストラクタ
  const AvatarActionBottomSheet({
    required this.hasAvatar,
    super.key,
  });

  /// 現在写真が設定されているかどうか
  final bool hasAvatar;

  /// ボトムシートを表示する静的ヘルパーメソッド
  static Future<AvatarActionType?> show(
    BuildContext context, {
    required bool hasAvatar,
  }) {
    return showModalBottomSheet<AvatarActionType>(
      context: context,
      showDragHandle: true,
      builder: (context) => AvatarActionBottomSheet(hasAvatar: hasAvatar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.profileAvatarSelectTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          // カメラで撮影
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.profileAvatarCamera),
            onTap: () => Navigator.of(context).pop(AvatarActionType.camera),
          ),
          // アルバムから選択
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.profileAvatarGallery),
            onTap: () => Navigator.of(context).pop(AvatarActionType.gallery),
          ),
          // 写真削除（既に設定されている場合のみ表示）
          if (hasAvatar)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
              ),
              title: Text(
                l10n.profileAvatarDelete,
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () => Navigator.of(context).pop(AvatarActionType.delete),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
