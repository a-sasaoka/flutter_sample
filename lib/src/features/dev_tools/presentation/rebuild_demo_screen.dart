import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/dev_tools/application/rebuild_demo_notifier.dart';
import 'package:flutter_sample/src/features/dev_tools/domain/rebuild_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ⚡️ パフォーマンス・再ビルド最適化検証デモ画面
///
/// Flutter DevTools（Widget Rebuild Tracker）および画面上のバッジを通じて、
/// Badモード（全画面巻き添え再描画）とGoodモード（select・Widget分割・constによる局所描画）
/// の違いを視覚的に体験できる検証用画面です。
class RebuildDemoScreen extends ConsumerStatefulWidget {
  /// コンストラクタ
  const RebuildDemoScreen({super.key});

  @override
  ConsumerState<RebuildDemoScreen> createState() => _RebuildDemoScreenState();
}

class _RebuildDemoScreenState extends ConsumerState<RebuildDemoScreen> {
  late final TextEditingController _searchController;

  // Goodモードのカード再描画回数をアイテムIDごとに保持するマップ
  final Map<int, int> _goodItemBuildCounts = {};

  // リセット時にカウンターと画面ツリーを初期化するためのユニークキー
  int _resetKey = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleReset() {
    ref.read(rebuildDemoProvider.notifier).reset();
    _searchController.clear();
    _goodItemBuildCounts.clear();
    setState(() {
      _resetKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOptimized = ref.watch(
      rebuildDemoProvider.select((state) => state.isOptimized),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devRebuildTitle),
        actions: [
          IconButton(
            key: const Key('reset_rebuild_demo_button'),
            icon: const Icon(Icons.refresh),
            tooltip: l10n.devRebuildResetButton,
            onPressed: _handleReset,
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(_resetKey),
        child: Column(
          children: [
            // 1. 最適化モード切り替えカード
            Card(
              margin: const EdgeInsets.all(16),
              child: SwitchListTile(
                key: const Key('toggle_rebuild_mode_switch'),
                value: isOptimized,
                title: Text(
                  isOptimized
                      ? l10n.devRebuildModeGood
                      : l10n.devRebuildModeBad,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOptimized ? Colors.green : Colors.red,
                  ),
                ),
                subtitle: Text(
                  isOptimized
                      ? l10n.devRebuildModeGoodDesc
                      : l10n.devRebuildModeBadDesc,
                  style: const TextStyle(fontSize: 12),
                ),
                secondary: Icon(
                  isOptimized ? Icons.speed : Icons.warning_amber_rounded,
                  color: isOptimized ? Colors.green : Colors.red,
                ),
                onChanged: (_) {
                  ref.read(rebuildDemoProvider.notifier).toggleOptimization();
                },
              ),
            ),

            // 2. モードに応じた検索・リストコンテンツ
            Expanded(
              child: isOptimized
                  ? _GoodRebuildView(
                      searchController: _searchController,
                      itemBuildCounts: _goodItemBuildCounts,
                    )
                  : _BadRebuildView(searchController: _searchController),
            ),
          ],
        ),
      ),
    );
  }
}

/// ビルド回数を視覚的に表示するバッジWidget
class RebuildTrackerBadge extends StatelessWidget {
  /// コンストラクタ
  const RebuildTrackerBadge({
    required this.label,
    required this.count,
    super.key,
  });

  /// 対象のラベル名
  final String label;

  /// ビルドされた回数
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // 回数に応じた警告カラー設定
    final Color badgeColor;
    if (count <= 1) {
      badgeColor = Colors.green;
    } else if (count <= 3) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        border: Border.all(color: badgeColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: ${l10n.devRebuildCountBadge(count)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}

// =============================================================================
// ❌ Badモード：アンチパターン実装
// 親が全体を watch し、小粒度分割も const もなく全てインラインで再描画される
// =============================================================================
class _BadRebuildView extends ConsumerStatefulWidget {
  const _BadRebuildView({required this.searchController});

  final TextEditingController searchController;

  @override
  ConsumerState<_BadRebuildView> createState() => _BadRebuildViewState();
}

class _BadRebuildViewState extends ConsumerState<_BadRebuildView> {
  // 親自身のビルド回数（親が再描画されるたびにインクリメント）
  int _buildCount = 0;

  // カード単位のビルド回数を追跡するマップ
  final Map<int, int> _itemBuildCounts = {};

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    // ⚠️ アンチパターン①：親Widgetで状態全体を watch
    final state = ref.watch(rebuildDemoProvider);
    final l10n = context.l10n;
    final allItems = getLocalizedRebuildItems(l10n);
    final items = allItems
        .where((item) => item.matchesQuery(state.searchQuery))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ⚠️ アンチパターン②：画面ルートの再描画バッジ（親のビルド回数を直接反映）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '画面全体エリア',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RebuildTrackerBadge(label: 'Root', count: _buildCount),
            ],
          ),
          const SizedBox(height: 8),

          // ⚠️ アンチパターン③：同一ビルドツリー内にインライン生成された検索バー
          TextField(
            key: const Key('rebuild_search_text_field'),
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: l10n.devRebuildSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (query) {
              ref.read(rebuildDemoProvider.notifier).updateSearchQuery(query);
            },
          ),
          const SizedBox(height: 12),

          // ⚠️ アンチパターン④：子Widgetをクラスに切り出さず、for文や関数で直接構築
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(l10n.devRebuildEmpty))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // 親がビルドされるたびに全アイテムも巻き添えで再生成される
                      return _buildBadItemCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ⚠️ 関数によるUI分割は Widget の小粒度化（再ビルド境界）にならない
  Widget _buildBadItemCard(BuildContext context, RebuildItem item) {
    final count = (_itemBuildCounts[item.id] ?? 0) + 1;
    _itemBuildCounts[item.id] = count;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                RebuildTrackerBadge(label: 'Item ${item.id}', count: count),
              ],
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(item.category, style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ✅ Goodモード：最適化された現場レベルの実装
// 処方箋① Widget分割 / 処方箋② select / 処方箋③ const徹底
// =============================================================================
class _GoodRebuildView extends StatelessWidget {
  // 処方箋③：静的な親コンポーネントは const で宣言
  const _GoodRebuildView({
    required this.searchController,
    required this.itemBuildCounts,
  });

  final TextEditingController searchController;
  final Map<int, int> itemBuildCounts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '画面全体エリア（分割済）',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // 親は const のため入力時に再描画されない！
              RebuildTrackerBadge(label: 'Root', count: 1),
            ],
          ),
          const SizedBox(height: 8),

          // 処方箋①：検索バーを独立したWidgetとして小粒度分割
          _GoodSearchBar(searchController: searchController),
          const SizedBox(height: 12),

          // 処方箋①＆②：リスト部分も独立し、select で購読
          Expanded(child: _GoodItemList(itemBuildCounts: itemBuildCounts)),
        ],
      ),
    );
  }
}

/// 処方箋①：独立した検索バーWidget
class _GoodSearchBar extends ConsumerStatefulWidget {
  const _GoodSearchBar({required this.searchController});

  final TextEditingController searchController;

  @override
  ConsumerState<_GoodSearchBar> createState() => _GoodSearchBarState();
}

class _GoodSearchBarState extends ConsumerState<_GoodSearchBar> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    // 処方箋②：検索クエリのみを select で監視し、入力時だけこのバーが再描画される
    ref.watch(rebuildDemoProvider.select((state) => state.searchQuery));
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          key: const Key('rebuild_search_text_field'),
          controller: widget.searchController,
          decoration: InputDecoration(
            hintText: l10n.devRebuildSearchHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onChanged: (query) {
            ref.read(rebuildDemoProvider.notifier).updateSearchQuery(query);
          },
        ),
        const SizedBox(height: 4),
        // 入力時だけこのバーのバッジのみが再描画される
        RebuildTrackerBadge(label: 'SearchBar', count: _buildCount),
      ],
    );
  }
}

/// 処方箋①＆②：select により絞り込み結果リストの変化のみを購読するリストWidget
class _GoodItemList extends ConsumerWidget {
  const _GoodItemList({required this.itemBuildCounts});

  final Map<int, int> itemBuildCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 処方箋②：検索クエリのみを select で監視し、絞り込み結果リストを再構築
    final searchQuery = ref.watch(
      rebuildDemoProvider.select((state) => state.searchQuery),
    );
    final l10n = context.l10n;
    final allItems = getLocalizedRebuildItems(l10n);
    final items = allItems
        .where((item) => item.matchesQuery(searchQuery))
        .toList();

    if (items.isEmpty) {
      return Center(child: Text(l10n.devRebuildEmpty));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // 処方箋①＆③：アイテムカードを独立したクラスに切り出し
        return _GoodItemCard(
          key: ValueKey(item.id),
          item: item,
          itemBuildCounts: itemBuildCounts,
        );
      },
    );
  }
}

/// 処方箋①：独立したアイテムカードWidget
class _GoodItemCard extends StatelessWidget {
  const _GoodItemCard({
    required this.item,
    required this.itemBuildCounts,
    super.key,
  });

  final RebuildItem item;
  final Map<int, int> itemBuildCounts;

  @override
  Widget build(BuildContext context) {
    final count = (itemBuildCounts[item.id] ?? 0) + 1;
    itemBuildCounts[item.id] = count;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                RebuildTrackerBadge(label: 'Item ${item.id}', count: count),
              ],
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(item.category, style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
