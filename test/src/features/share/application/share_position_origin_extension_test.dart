import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/share/application/share_position_origin_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharePositionOriginBuildContextX', () {
    testWidgets('ウィジェットがレンダリングされている場合に正しいRectを取得できること', (tester) async {
      Rect? capturedOrigin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 100,
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        capturedOrigin = context.sharePositionOrigin;
                      },
                      child: const Text('Test Button'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Button'));
      await tester.pump();

      check(capturedOrigin).isNotNull();
      check(capturedOrigin!.width).equals(200);
      check(capturedOrigin!.height).equals(100);
    });

    testWidgets('レンダリングされていないコンテキストではnullを返すこと', (tester) async {
      Rect? capturedOrigin;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedOrigin = context.sharePositionOrigin;
              return const SizedBox();
            },
          ),
        ),
      );

      check(capturedOrigin).isNull();
    });
  });
}
