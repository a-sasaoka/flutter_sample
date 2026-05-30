import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// メモ一覧の読み込み中に表示する骨組み（Shimmer）リスト
class MemoListShimmer extends StatelessWidget {
  /// コンストラクタ
  const MemoListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面の高さに合わせて、表示するカードの数を動的に計算します
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        // カード1枚の想定の高さ（余白を含めて約100ピクセル）
        const cardHeight = 100.0;
        // 画面に収まる枚数を計算（最低1枚、最大10枚）
        final itemCount = (screenHeight / cardHeight).ceil().clamp(1, 10);

        return ListView.builder(
          // スケルトン表示中はユーザーがスクロールできないようにします
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: itemCount,
          itemBuilder: (context, index) => const MemoCardShimmer(),
        );
      },
    );
  }
}

/// メモカードの形を模した1枚の骨組み（Shimmer）部品
class MemoCardShimmer extends StatelessWidget {
  /// コンストラクタ
  const MemoCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // ダークモード（暗い画面設定）かどうかを判定します
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ダークモードとライトモードで、キラキラさせるグレーの色を切り替えます
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // タイトルを模した長方形のグレーボックス
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 本文を模した長方形のグレーボックス
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 同期状態アイコンと時間を模したグレーボックス
                    Row(
                      children: [
                        // アイコンの丸いプレースホルダー
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 同期ステータス文字のプレースホルダー
                        Container(
                          width: 50,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        // 作成日時のプレースホルダー
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 右側のゴミ箱ボタンを模したプレースホルダー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
