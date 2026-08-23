import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_notifier.g.dart';

/// アプリの初回起動（オンボーディング）の状態を管理するNotifier
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  FutureOr<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    // 保存されているオンボーディング完了フラグを取得します（デフォルトはfalse）
    return await prefs.getBool(SharedPrefKeys.onboardingCompleted) ?? false;
  }

  /// オンボーディングを完了状態にする
  Future<void> complete() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = ref.read(sharedPreferencesProvider);
      // オンボーディング完了フラグをtrueにして保存します
      await prefs.setBool(SharedPrefKeys.onboardingCompleted, true);
      return true;
    });
  }
}
