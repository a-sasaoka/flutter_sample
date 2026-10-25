import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/widgets/highlighted_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HighlightedText Widget テスト', () {
    testWidgets('【正常系】検索語が空の場合は通常のTextが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(text: 'Hello World', highlight: ''),
          ),
        ),
      );

      final textFinder = find.byType(Text);
      check(textFinder.evaluate().isNotEmpty).isTrue();

      final textWidget = tester.widget<Text>(textFinder);
      check(textWidget.data).equals('Hello World');
    });

    testWidgets('【境界値】textが空の場合は空のTextが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(text: '', highlight: 'flutter'),
          ),
        ),
      );

      final textFinder = find.byType(Text);
      check(textFinder.evaluate().isNotEmpty).isTrue();

      final textWidget = tester.widget<Text>(textFinder);
      check(textWidget.data).equals('');
    });

    testWidgets('【正常系】キーワードと一致する部分がハイライトスタイルで分割表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Hello Flutter World',
              highlight: 'Flutter',
            ),
          ),
        ),
      );

      final textFinder = find.byType(Text);
      final textWidget = tester.widget<Text>(textFinder);
      final textSpan = textWidget.textSpan! as TextSpan;

      // 3分割（'Hello ', 'Flutter', ' World'）
      check(textSpan.children?.length).equals(3);

      final beforeSpan = textSpan.children![0] as TextSpan;
      final highlightSpan = textSpan.children![1] as TextSpan;
      final afterSpan = textSpan.children![2] as TextSpan;

      check(beforeSpan.text).equals('Hello ');
      check(highlightSpan.text).equals('Flutter');
      check(afterSpan.text).equals(' World');

      // ハイライト部分にスタイル（太字）が適用されていること
      check(highlightSpan.style?.fontWeight).equals(FontWeight.bold);
    });

    testWidgets('【正常系】大文字・小文字を区別せずハイライトされること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'dart and DART and Dart',
              highlight: 'dart',
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      final textSpan = textWidget.textSpan! as TextSpan;

      // 'dart', ' and ', 'DART', ' and ', 'Dart' の計5つ
      check(textSpan.children?.length).equals(5);

      final span0 = textSpan.children![0] as TextSpan;
      final span2 = textSpan.children![2] as TextSpan;
      final span4 = textSpan.children![4] as TextSpan;

      check(span0.text).equals('dart');
      check(span2.text).equals('DART');
      check(span4.text).equals('Dart');
    });

    testWidgets('【正常系】カスタムスタイル、maxLines、overflowが反映されること', (tester) async {
      const customStyle = TextStyle(fontSize: 18, color: Colors.blue);
      const customHighlightStyle = TextStyle(
        fontSize: 20,
        color: Colors.red,
        backgroundColor: Colors.yellow,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Custom Highlight Style Test',
              highlight: 'Highlight',
              style: customStyle,
              highlightStyle: customHighlightStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      check(textWidget.maxLines).equals(2);
      check(textWidget.overflow).equals(TextOverflow.ellipsis);

      final textSpan = textWidget.textSpan! as TextSpan;
      final highlightSpan = textSpan.children![1] as TextSpan;
      check(highlightSpan.style?.color).equals(Colors.red);
      check(highlightSpan.style?.backgroundColor).equals(Colors.yellow);
    });
  });
}
