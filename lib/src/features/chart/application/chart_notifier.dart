import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chart/application/chart_state.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_item.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_notifier.g.dart';

/// グラフデータの状態を管理するNotifier
@Riverpod(keepAlive: true)
class ChartNotifier extends _$ChartNotifier {
  @override
  ChartState build() {
    // 認証状態の変化（ログアウトや別アカウントへの切り替え）を監視し、
    // 入力中グラフデータを自律的にリセットする
    ref
      ..listen<String?>(currentUserIdProvider, (previous, next) {
        if (previous != next) {
          reset();
        }
      })
      ..listen<bool>(isAuthenticatedProvider, (previous, next) {
        if (previous != next) {
          reset();
        }
      });

    return const ChartState();
  }

  /// グラフの種類を変更する
  void updateChartType(ChartType type) {
    state = state.copyWith(chartType: type);
  }

  /// 新しい項目を追加する
  void addItem() {
    final nextCounter = state.itemCounter + 1;
    final uuid = ref.read(uuidProvider);

    state = state.copyWith(
      itemCounter: nextCounter,
      items: [
        ...state.items,
        ChartItem(id: uuid.v4(), label: 'Item$nextCounter'),
      ],
    );
  }

  /// 指定したIDの項目を削除する
  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  /// 全ての項目を削除（リセット）する
  void reset() {
    state = const ChartState(items: [], itemCounter: 0);
  }

  /// 指定したIDの項目の名前を更新する
  void updateLabel(String id, String label) {
    state = state.copyWith(
      items: state.items.map((item) {
        return item.id == id ? item.copyWith(label: label) : item;
      }).toList(),
    );
  }

  /// 指定したIDの項目の数値を更新する
  void updateValue(String id, double value) {
    state = state.copyWith(
      items: state.items.map((item) {
        return item.id == id ? item.copyWith(value: value) : item;
      }).toList(),
    );
  }
}
