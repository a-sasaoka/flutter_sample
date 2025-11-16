import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// アプリ全体のロケールを管理するプロバイダ
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'locale_key';

  @override
  Future<Locale?> build() async {
    // SharedPreferences を読み込み、保存されていればその Locale を返す
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final code = await prefs.getString(_key);

    if (code == null || code.isEmpty) {
      return null; // システムに従う
    }
    return Locale(code);
  }

  /// ロケールを設定（"ja", "en" など）
  Future<void> setLocale(String? languageCode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);

    if (languageCode == null) {
      // システム設定に戻す
      await prefs.remove(_key);
      state = const AsyncData(null);
      return;
    }

    await prefs.setString(_key, languageCode);
    state = AsyncData(Locale(languageCode));
  }
}
