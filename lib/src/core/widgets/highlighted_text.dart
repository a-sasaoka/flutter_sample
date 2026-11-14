import 'package:flutter/material.dart';

/// 🔍 検索キーワードと一致する文字列をハイライト表示する Widget
class HighlightedText extends StatelessWidget {
  /// コンストラクタ
  const HighlightedText({
    required this.text,
    required this.highlight,
    super.key,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  /// 表示対象の全文
  final String text;

  /// ハイライトしたい検索キーワード
  final String highlight;

  /// 通常テキストのスタイル
  final TextStyle? style;

  /// ハイライト部分のテキストスタイル
  final TextStyle? highlightStyle;

  /// 最大行数
  final int? maxLines;

  /// 枠からあふれた場合の表示方法
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final trimmedHighlight = highlight.trim();
    // 検索語が空、または本文が空の場合は通常のTextを返す
    if (trimmedHighlight.isEmpty || text.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final theme = Theme.of(context);
    // テーマに連動したデフォルトのハイライト色
    final defaultHighlightStyle = TextStyle(
      backgroundColor: theme.colorScheme.primaryContainer,
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.bold,
    );
    final effectiveHighlightStyle = highlightStyle ?? defaultHighlightStyle;

    final spans = <InlineSpan>[];
    final lowerText = text.toLowerCase();
    final lowerHighlight = trimmedHighlight.toLowerCase();

    var startIndex = 0;
    while (startIndex < text.length) {
      final matchIndex = lowerText.indexOf(lowerHighlight, startIndex);
      if (matchIndex == -1) {
        // 残りの一致しなかった通常テキストを追加して終了
        spans.add(TextSpan(text: text.substring(startIndex), style: style));
        break;
      }

      // 一致箇所の前にある通常テキストを追加
      if (matchIndex > startIndex) {
        spans.add(
          TextSpan(text: text.substring(startIndex, matchIndex), style: style),
        );
      }

      // 一致したキーワード部分を追加（元の文字列の大文字・小文字を保持）
      final endIndex = matchIndex + lowerHighlight.length;
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, endIndex),
          style: effectiveHighlightStyle,
        ),
      );

      startIndex = endIndex;
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
