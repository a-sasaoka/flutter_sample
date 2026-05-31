# テーマ設定（FlexColorScheme）

本プロジェクトでは、美しく一貫性のあるUIを効率的に構築するために [FlexColorScheme](https://pub.dev/packages/flex_color_scheme) を採用しています。
Material 3 に完全対応し、ライト／ダーク／システムモードのシームレスな切り替えを実現しています。

## 📁 主なファイル構成

```plaintext
lib/src/core/config/
 ├── app_theme.dart           # テーマの具体的な定義（色・形状・スタイル）
 └── theme_mode_provider.dart # ユーザーが選択したモード（Light/Dark/System）の状態管理
```

---

## ✨ 主な特徴

- **Material 3 準拠**: 最新の Android/iOS のデザインガイドラインに自動で適合します。
- **高度なカスタマイズ**: `FlexThemeData` を通じて、ボタンの角丸、カードの影、色のシード値を一括で制御できます。
- **シームレスな切り替え**: Riverpod で `ThemeMode` を管理しているため、設定変更が即座にアプリ全体に反映されます。

---

## 🎨 UI部品のテーマ連動（一貫性の確保）

本プロジェクトでは、標準ウィジェットだけでなく、共通の UI 拡張機能もアプリのテーマに連動するように設計されています。

### スナックバーの自動配色 (`SnackBarExtension`)

`context.showSnackBar()` 等で表示されるスナックバーは、`Theme.of(context).colorScheme` から直接色を取得します。

- **エラー**: `errorContainer` (背景) / `onErrorContainer` (文字・アイコン)
- **成功**: `primaryContainer` (背景) / `onPrimaryContainer` (文字・アイコン)
- **情報**: `secondaryContainer` (背景) / `onSecondaryContainer` (文字・アイコン)

これにより、`FlexColorScheme` でテーマ（`FlexScheme`）を切り替えるだけで、スナックバーを含むアプリ全体の配色が自動的に最適化されます。

---

## 💾 永続化の仕組み（SharedPreferencesAsync）

ユーザーが変更したテーマ設定（ライトモード固定など）は、`SharedPreferencesAsync` を通じてデバイスに保存されます。

1. **保存**: `ThemeModeProvider` 内で設定が変更されるたびに、非同期でストレージに書き込みます。
2. **復元**: アプリ起動時、`themeModeProvider` がストレージから値を読み取り、前回の設定を自動的に適用します。

`SharedPreferencesAsync` を利用しているため、メインスレッド（UI）をブロックすることなく、高速な起動と永続化を両立しています。

---

## 🏗 アプリへの適用

`MyApp` 内で `themeModeProvider` を監視（watch）し、`MaterialApp` の各プロパティに流し込んでいます。

```dart
// main.dart 等での利用イメージ
final themeMode = ref.watch(themeModeProvider);

return MaterialApp.router(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: themeMode, // 💡 状態に応じて自動切り替え
  // ...
);
```

---

## 🧪 テスト手法

テーマ設定が期待通りに動作するかを検証するために、以下のテストを実施しています。

- **Providerテスト**: `ThemeMode` を変更した際に、ストレージへ正しく保存されるか、状態が更新されるかを検証します。
- **Widgetテスト**: テーマの変更によって、特定のWidgetの色やスタイルが意図した通りに変化するかを確認します。

```dart
// テスト例
test('テーマモードを変更すると状態が更新されること', () async {
  final container = createContainer();
  final notifier = container.read(themeModeProvider.notifier);

  await notifier.setThemeMode(ThemeMode.dark);
  check(container.read(themeModeProvider)).equals(ThemeMode.dark);
});
```

---
