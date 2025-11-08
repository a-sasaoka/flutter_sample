import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// アプリ全体で共有する SharedPreferences プロバイダ
///
/// - keepAlive: true → disposeされず常駐
/// - 実際のインスタンスは runApp 前に override して渡す
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(); // 実際は main() で上書きして注入
}
