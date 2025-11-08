// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリのテーマモード（ライト・ダーク・システム）を管理するProvider。
///
/// 初期状態は `ThemeMode.system`（端末設定に追従）
///
/// 利用例:
/// ```dart
/// final mode = ref.watch(themeModeNotifierProvider);
/// ref.read(themeModeNotifierProvider.notifier).toggleLightDark();
/// ```

@ProviderFor(ThemeModeNotifier)
const themeModeProvider = ThemeModeNotifierProvider._();

/// アプリのテーマモード（ライト・ダーク・システム）を管理するProvider。
///
/// 初期状態は `ThemeMode.system`（端末設定に追従）
///
/// 利用例:
/// ```dart
/// final mode = ref.watch(themeModeNotifierProvider);
/// ref.read(themeModeNotifierProvider.notifier).toggleLightDark();
/// ```
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// アプリのテーマモード（ライト・ダーク・システム）を管理するProvider。
  ///
  /// 初期状態は `ThemeMode.system`（端末設定に追従）
  ///
  /// 利用例:
  /// ```dart
  /// final mode = ref.watch(themeModeNotifierProvider);
  /// ref.read(themeModeNotifierProvider.notifier).toggleLightDark();
  /// ```
  const ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'ea42ab2556c3d78dcf9920eaf3b79cdd47009751';

/// アプリのテーマモード（ライト・ダーク・システム）を管理するProvider。
///
/// 初期状態は `ThemeMode.system`（端末設定に追従）
///
/// 利用例:
/// ```dart
/// final mode = ref.watch(themeModeNotifierProvider);
/// ref.read(themeModeNotifierProvider.notifier).toggleLightDark();
/// ```

abstract class _$ThemeModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
