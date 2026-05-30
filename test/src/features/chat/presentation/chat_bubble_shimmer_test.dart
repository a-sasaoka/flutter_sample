import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_bubble_shimmer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  group('ChatBubbleShimmer ウィジェットテスト', () {
    testWidgets('ライトモードで骨組み（Shimmer）と吹き出しボックスが正しく描画されること', (tester) async {
      // 1. テスト用の画面にウィジェットを表示します
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubbleShimmer(),
          ),
        ),
      );

      // 2. キラキラ効果（Shimmer）が1つ表示されていることを確認します
      expect(find.byType(Shimmer), findsOneWidget);

      // 3. 吹き出しやダミーテキストを模した四角いコンテナ（Container）が描画されていることを確認します
      // 吹き出し外枠 + テキスト1行目 + テキスト2行目 + 時間 のため、複数存在します
      expect(find.byType(Container), findsAtLeastNWidgets(3));
    });

    testWidgets('ダークモードで骨組み（Shimmer）と吹き出しボックスが正しく描画されること', (tester) async {
      // 1. ダークモード用のテーマを設定して画面を表示します
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ChatBubbleShimmer(),
          ),
        ),
      );

      // 2. ダークモードでも同様にShimmerが表示されていることを確認します
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(Container), findsAtLeastNWidgets(3));
    });
  });
}
