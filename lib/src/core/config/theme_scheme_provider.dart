import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_scheme_provider.g.dart';

/// 🎨 テーマカラー（カラースキーム）の状態を管理・保存するプロバイダー
@Riverpod(keepAlive: true)
class ThemeSchemeNotifier extends _$ThemeSchemeNotifier {
  /// デフォルトのカラースキーム（藍色）
  static const FlexScheme defaultScheme = FlexScheme.indigoM3;

  @override
  Future<FlexScheme> build() async {
    // SharedPreferencesから設定を取得
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = await prefs.getString(SharedPrefKeys.themeScheme);

    if (value == null) {
      return defaultScheme;
    }

    return FlexScheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultScheme,
    );
  }

  Future<void> _lastOperation = Future.value();

  /// カラースキームを変更して保存
  Future<void> setScheme(FlexScheme scheme) {
    final operation = () async {
      try {
        await _lastOperation;
      } on Object catch (_) {
        // 直前の保存が失敗した場合でも後続の保存を継続
      }
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(SharedPrefKeys.themeScheme, scheme.name);
      state = AsyncData(scheme);
    }();
    _lastOperation = operation;
    return operation;
  }
}
