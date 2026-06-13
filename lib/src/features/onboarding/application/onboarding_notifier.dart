import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_notifier.g.dart';

/// アプリの初回起動（オンボーディング）の状態を管理するNotifier
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  static const _key = 'onboarding_completed';

  @override
  FutureOr<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    // 保存されているオンボーディング完了フラグを取得します（デフォルトはfalse）
    return await prefs.getBool(_key) ?? false;
  }

  /// オンボーディングを完了状態にする
  Future<void> complete() async {
    state = const AsyncValue.loading();
    final prefs = ref.watch(sharedPreferencesProvider);
    // オンボーディング完了フラグをtrueにして保存します
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(true);
  }
}
