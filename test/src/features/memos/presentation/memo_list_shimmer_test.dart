import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_list_shimmer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  group('MemoListShimmer ウィジェットテスト', () {
    testWidgets('画面の高さに合わせて、正しい枚数の骨組みカードが描画されること', (tester) async {
      // 1. テスト画面のサイズを横400ピクセル、縦600ピクセルに固定します
      tester.view.physicalSize = const Size(400, 600);
      // デバイスピクセル比を1にして、ピクセル計算を単純にします
      tester.view.devicePixelRatio = 1.0;

      // テスト終了時に画面サイズとデバイスピクセル比を元に戻すようにします
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 2. 仮想の画面に MemoListShimmer を表示します
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemoListShimmer(),
          ),
        ),
      );

      // 3. 画面の高さ（600px）÷ カードの高さ（100px）＝ 6 枚 のカードが表示されているはずです
      // MemoCardShimmer がちょうど6枚あるか確認します
      check(find.byType(MemoCardShimmer)).findsExactly(6);

      // 4. キラキラ効果（Shimmer）が使われていることを確認します
      check(find.byType(Shimmer)).findsAtLeast(1);
    });

    testWidgets('ダークモードでもエラーなく骨組みカードが描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: MemoListShimmer(),
          ),
        ),
      );

      // ダークモードでも骨組みカードが1枚以上表示されていることを確認します
      check(find.byType(MemoCardShimmer)).findsAtLeast(1);
    });
  });
}
