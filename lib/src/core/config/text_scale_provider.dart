import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'text_scale_provider.g.dart';

/// 🔤 選択可能な文字サイズプリセット
enum AppTextScale {
  /// 小（0.85倍）
  small(0.85),

  /// 標準（1.0倍）
  normal(1),

  /// 大（1.15倍）
  large(1.15);

  const AppTextScale(this.scale);

  /// テキストの拡大縮小倍率
  final double scale;
}

/// 🔍 アプリ全体の文字サイズ倍率を管理・永続化するプロバイダー
@Riverpod(keepAlive: true)
class TextScaleNotifier extends _$TextScaleNotifier {
  /// 初期値（標準: 1.0倍）
  static const AppTextScale defaultScale = AppTextScale.normal;

  @override
  Future<AppTextScale> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = await prefs.getString(SharedPrefKeys.textScale);
    if (value == null) {
      return defaultScale;
    }

    return AppTextScale.values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultScale,
    );
  }

  Future<void> _lastOperation = Future.value();

  /// 文字サイズを変更してローカルストレージに永続化
  Future<void> setScale(AppTextScale scale) {
    final operation = () async {
      try {
        await _lastOperation;
      } on Object catch (_) {
        // 直前の保存が失敗した場合でも後続の保存を継続
      }
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(SharedPrefKeys.textScale, scale.name);
      state = AsyncData(scale);
    }();
    _lastOperation = operation;
    return operation;
  }
}
