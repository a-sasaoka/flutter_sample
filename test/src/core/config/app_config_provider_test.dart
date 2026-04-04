import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MockThemeModeNotifier extends ThemeModeNotifier {
  MockThemeModeNotifier(this._mode);
  final ThemeMode _mode;
  @override
  Future<ThemeMode> build() async => _mode;
}

class MockLocaleNotifier extends LocaleNotifier {
  MockLocaleNotifier(this._locale);
  final Locale? _locale;
  @override
  Future<Locale?> build() async => _locale;
}

void main() {
  group('appConfigProvider テスト', () {
    test('ルーター、テーマ、言語設定が正しく取得され、Recordとして合体して返されること', () async {
      // Arrange (準備)
      // 1. 各プロバイダーが返すダミー値を用意します
      final dummyRouter = GoRouter(routes: []); // 空のルーター
      const dummyTheme = ThemeMode.dark; // ダークモード
      const dummyLocale = Locale('ja', 'JP'); // 日本語

      // 2. コンテナを作成し、3つの依存プロバイダーをすべてダミー値に差し替えます
      final container = ProviderContainer(
        overrides: [
          // routerProvider が関数の場合：
          routerProvider.overrideWith((ref) => dummyRouter),

          // Notifier クラスの場合は overrideWith(() => ...) の形式で指定
          themeModeProvider.overrideWith(
            () => MockThemeModeNotifier(dummyTheme),
          ),
          localeProvider.overrideWith(() => MockLocaleNotifier(dummyLocale)),
        ],
      );
      addTearDown(container.dispose);

      // Act (実行)
      // appConfig は非同期（Future）なので、`.future` を付けて await します
      final config = await container.read(appConfigProvider.future);

      // Assert (検証)
      // Record の各プロパティ（名前付きフィールド）がダミー値と完全に一致するか確認します
      expect(config.router, equals(dummyRouter));
      expect(config.theme, equals(dummyTheme));
      expect(config.locale, equals(dummyLocale));
    });
  });
}
