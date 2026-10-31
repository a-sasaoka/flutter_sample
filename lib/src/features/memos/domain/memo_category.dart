import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';

/// 🏷️ メモのカテゴリ（タグ）を表すデータ（列挙型）
enum MemoCategory {
  /// 仕事
  work,

  /// 個人・プライベート
  personal,

  /// アイデア
  idea;

  /// 多言語化に対応したラベル文字列を返します
  String label(AppLocalizations l10n) => switch (this) {
    MemoCategory.work => l10n.memoCategoryWork,
    MemoCategory.personal => l10n.memoCategoryPersonal,
    MemoCategory.idea => l10n.memoCategoryIdea,
  };

  /// カテゴリに対応するアイコンを返します
  IconData get icon => switch (this) {
    MemoCategory.work => Icons.work_outline,
    MemoCategory.personal => Icons.person_outline,
    MemoCategory.idea => Icons.lightbulb_outline,
  };
}
