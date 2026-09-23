import 'package:freezed_annotation/freezed_annotation.dart';

part 'rebuild_item.freezed.dart';

/// 開発者向けパフォーマンス・再ビルド検証用のアイテムモデル
@freezed
sealed class RebuildItem with _$RebuildItem {
  /// コンストラクタ
  const factory RebuildItem({
    required int id,
    required String name,
    required String category,
    required String description,
  }) = _RebuildItem;
}

/// 検証用の初期Widgetアイテムリスト
const defaultRebuildItems = <RebuildItem>[
  RebuildItem(
    id: 1,
    name: 'Container',
    category: 'レイアウト',
    description: 'サイズ・余白・背景色などを装飾する万能ボックスWidget',
  ),
  RebuildItem(
    id: 2,
    name: 'ListView.builder',
    category: 'スクロール',
    description: '画面外のアイテムを遅延生成し、メモリを節約するスクロールリスト',
  ),
  RebuildItem(
    id: 3,
    name: 'AnimatedContainer',
    category: 'アニメーション',
    description: 'プロパティの変更を検知して自動で滑らかにアニメーションするWidget',
  ),
  RebuildItem(
    id: 4,
    name: 'TextField',
    category: '入力',
    description: 'ユーザーがテキストを入力・編集できるフィールドWidget',
  ),
  RebuildItem(
    id: 5,
    name: 'ElevatedButton',
    category: 'ボタン',
    description: '立体的な影とタップ時の波紋エフェクトを持つマテリアルボタン',
  ),
  RebuildItem(
    id: 6,
    name: 'Switch',
    category: '入力',
    description: '設定やフラグのON・OFFを直感的に切り替えるトグルスイッチ',
  ),
  RebuildItem(
    id: 7,
    name: 'Shimmer',
    category: 'UI演出',
    description: '読み込み中にキラリと光る骨組みを表示し、体感速度を高める演出',
  ),
  RebuildItem(
    id: 8,
    name: 'CustomPaint',
    category: '描画',
    description: 'Canvas APIを使って自由自在なグラフィックや図形を描画するWidget',
  ),
  RebuildItem(
    id: 9,
    name: 'Stack',
    category: 'レイアウト',
    description: '複数の子Widgetを前後に重ね合わせて立体的に配置するレイアウト',
  ),
  RebuildItem(
    id: 10,
    name: 'Hero',
    category: '画面遷移',
    description: '2つの画面間をまたいで同じ要素が飛行するように移動するアニメーション',
  ),
];
