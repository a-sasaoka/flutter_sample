import 'package:flutter_sample/l10n/app_localizations.dart';
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

  const RebuildItem._();

  /// 検索クエリと合致するかどうかを判定する
  bool matchesQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return true;
    }
    return name.toLowerCase().contains(trimmed) ||
        category.toLowerCase().contains(trimmed) ||
        description.toLowerCase().contains(trimmed);
  }
}

/// [AppLocalizations] を用いてローカライズされた検証用アイテム一覧を取得する
List<RebuildItem> getLocalizedRebuildItems(AppLocalizations l10n) {
  return [
    RebuildItem(
      id: 1,
      name: 'Container',
      category: l10n.devRebuildItemContainerCategory,
      description: l10n.devRebuildItemContainerDesc,
    ),
    RebuildItem(
      id: 2,
      name: 'ListView.builder',
      category: l10n.devRebuildItemListViewCategory,
      description: l10n.devRebuildItemListViewDesc,
    ),
    RebuildItem(
      id: 3,
      name: 'AnimatedContainer',
      category: l10n.devRebuildItemAnimatedContainerCategory,
      description: l10n.devRebuildItemAnimatedContainerDesc,
    ),
    RebuildItem(
      id: 4,
      name: 'TextField',
      category: l10n.devRebuildItemTextFieldCategory,
      description: l10n.devRebuildItemTextFieldDesc,
    ),
    RebuildItem(
      id: 5,
      name: 'ElevatedButton',
      category: l10n.devRebuildItemElevatedButtonCategory,
      description: l10n.devRebuildItemElevatedButtonDesc,
    ),
    RebuildItem(
      id: 6,
      name: 'Switch',
      category: l10n.devRebuildItemSwitchCategory,
      description: l10n.devRebuildItemSwitchDesc,
    ),
    RebuildItem(
      id: 7,
      name: 'Shimmer',
      category: l10n.devRebuildItemShimmerCategory,
      description: l10n.devRebuildItemShimmerDesc,
    ),
    RebuildItem(
      id: 8,
      name: 'CustomPaint',
      category: l10n.devRebuildItemCustomPaintCategory,
      description: l10n.devRebuildItemCustomPaintDesc,
    ),
    RebuildItem(
      id: 9,
      name: 'Stack',
      category: l10n.devRebuildItemStackCategory,
      description: l10n.devRebuildItemStackDesc,
    ),
    RebuildItem(
      id: 10,
      name: 'Hero',
      category: l10n.devRebuildItemHeroCategory,
      description: l10n.devRebuildItemHeroDesc,
    ),
  ];
}

/// 検証用の初期Widgetアイテムリスト（フォールバック用）
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
