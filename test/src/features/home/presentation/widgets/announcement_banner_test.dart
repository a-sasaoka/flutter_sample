import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/home/presentation/widgets/announcement_banner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnouncementBanner Widget Tests', () {
    testWidgets('メッセージが空文字の場合はSizedBox.shrinkとなり何も描画されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnnouncementBanner(message: '')),
        ),
      );

      check(find.byType(Card).evaluate().isEmpty).isTrue();
      check(find.byType(SizedBox).evaluate().isNotEmpty).isTrue();
    });

    testWidgets('メッセージがある場合はCardとメッセージテキスト、アイコンが描画されること', (tester) async {
      const message = 'メンテナンスのお知らせ';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnnouncementBanner(message: message)),
        ),
      );

      check(find.byType(Card).evaluate().length).equals(1);
      check(find.text(message).evaluate().length).equals(1);
      check(find.byIcon(Icons.campaign_outlined).evaluate().length).equals(1);
    });
  });
}
