import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// SharedPreferencesAsync をアプリ全体で共有する Provider
///
/// - 非同期で安全に利用可能
/// - 起動時に待ち時間が発生しない
/// - テスト時に差し替えやすい
@Riverpod(keepAlive: true)
Future<SharedPreferencesAsync> sharedPreferences(Ref ref) async {
  return SharedPreferencesAsync();
}
