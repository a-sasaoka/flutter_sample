// SharedPreferences を使ってテーマモードを永続化する。

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
    final prefs = await ref.read(sharedPreferencesProvider.future);
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
    await prefs.setString(_key, mode.valeu);
  }

  /// トグル切り替え
  Future<void> toggleLightDark() async {
    final current = state.value ?? ThemeMode.system;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

/// ThemeMode 拡張メソッド
extension _ThemeModeExt on ThemeMode {
  /// 文字列を取得
  String get valeu => {
    ThemeMode.light: 'light',
    ThemeMode.dark: 'dark',
    ThemeMode.system: 'system',
  }[this]!;
}

/// String 拡張メソッド
extension _ThemeModeFromString on String {
  /// 文字列から ThemeMode に変換
  ThemeMode toThemeMode() {
    switch (this) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        throw Exception('Invalid theme: $this');
    }
  }
}
