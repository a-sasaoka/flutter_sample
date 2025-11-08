// lib/src/core/config/theme_mode_provider.dart
// SharedPreferences を使ってテーマモードを永続化するアノテーション版。

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

/// テーマモードの状態を管理・保存するプロバイダー
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode'; // 保存用キー

  @override
  Future<ThemeMode> build() async {
    // SharedPreferencesから設定を取得
    final prefs = ref.read(sharedPreferencesProvider);
    final value = prefs.getString(_key);

    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// モードを変更して保存
  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode); // 即時反映
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _modeToString(mode));
  }

  /// トグル切り替え
  Future<void> toggleLightDark() async {
    final current = state.value ?? ThemeMode.system;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }

  /// 内部的に ThemeMode ⇄ String を変換
  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
