// lib/src/core/config/theme_mode_provider.dart
// Riverpodアノテーション版のThemeMode管理Provider。
// コード生成により型安全で補完が効く構成になります。

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// アプリのテーマモード（ライト・ダーク・システム）を管理するProvider。
///
/// 初期状態は `ThemeMode.system`（端末設定に追従）
///
/// 利用例:
/// ```dart
/// final mode = ref.watch(themeModeNotifierProvider);
/// ref.read(themeModeNotifierProvider.notifier).toggleLightDark();
/// ```
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    // 初期値: システム設定に追従
    return ThemeMode.system;
  }

  /// 任意のモードを設定
  void set(ThemeMode mode) {
    Logger().d('ThemeMode changed to: $mode');
    state = mode;
  }

  /// ライト・ダークのトグル切り替え
  void toggleLightDark() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }
}
