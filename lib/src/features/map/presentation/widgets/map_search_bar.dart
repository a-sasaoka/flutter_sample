import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';

/// 🗺️ 地図画面上部に表示される住所・ランドマーク検索バー
class MapSearchBar extends StatelessWidget {
  /// コンストラクタ
  const MapSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSubmitted,
    required this.onClear,
    super.key,
  });

  /// 検索テキストコントローラ
  final TextEditingController controller;

  /// 検索入力フォーカスノード
  final FocusNode focusNode;

  /// 検索実行中ローディングフラグ
  final bool isLoading;

  /// 検索実行時コールバック（確定時または送信ボタン押下時）
  final ValueChanged<String> onSubmitted;

  /// 検索クリアボタン押下時コールバック
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('mapSearchTextField'),
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.mapSearchHint,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                key: const Key('mapSearchClearButton'),
                                icon: const Icon(Icons.clear),
                                tooltip: l10n.mapSearchClear,
                                onPressed: onClear,
                              )
                            : null,
                      ),
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      key: const Key('mapSearchButton'),
                      icon: const Icon(Icons.send),
                      onPressed: () => onSubmitted(controller.text),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
