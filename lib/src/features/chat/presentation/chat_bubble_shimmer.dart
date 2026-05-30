import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// AIチャットの返答待ちのときに表示する骨組み（Shimmer）部品
class ChatBubbleShimmer extends StatelessWidget {
  /// コンストラクタ
  const ChatBubbleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // ダークモード（暗い画面設定）かどうかを判定します
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ダークモードとライトモードで、キラキラさせるグレーの色を切り替えます
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        // AIの吹き出しなので画面の左側に寄せます
        alignment: Alignment.centerLeft,
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 吹き出しを模したコンテナ
              Container(
                constraints: BoxConstraints(
                  // 画面の幅の75%を上限とします
                  maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // AI発言の1行目を模した長方形
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // AI発言 of 2行目を模した長方形
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 時間表示を模した小さなグレーボックス
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  width: 30,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
