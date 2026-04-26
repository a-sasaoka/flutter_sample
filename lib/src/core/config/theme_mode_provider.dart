import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// テーマモードの状態を管理・保存するプロバイダー
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode'; // 保存用キー

  @override
  Future<ThemeMode> build() async {
    // SharedPreferencesから設定を取得
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final value = await prefs.getString(_key);

    // 保存されていなければシステム設定を返す
    if (value == null) {
      return ThemeMode.system;
    }

    return value.toThemeMode();
  }

  /// モードを変更して保存
  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode); // 即時反映
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, mode.name);
  }

  /// トグル切り替え
  Future<void> toggleLightDark() async {
    final current = state.value ?? ThemeMode.system;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

/// String 拡張メソッド
extension _ThemeModeFromString on String {
  /// 文字列から ThemeMode に変換
  ThemeMode toThemeMode() {
    return ThemeMode.values.firstWhere(
      (e) => e.name == this,
      orElse: () => ThemeMode.system,
    );
  }
}
