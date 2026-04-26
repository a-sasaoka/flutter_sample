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

## 🛠 テーマのカスタマイズ方法

アプリ全体のカラーテーマ（配色）を変更したい場合は、`lib/src/core/config/app_theme.dart` 内の `FlexScheme` を変更してください。

```dart
// app_theme.dart 内の定義例
static ThemeData light() => FlexThemeData.light(
      scheme: FlexScheme.blueWhale, // 💡 ここを変えるだけで配色をガラッと変更可能！
      useMaterial3: true,
      // ... その他の詳細なカスタマイズ
    );
```

利用可能なスキーム一覧は [FlexColorScheme 公式デモ](https://www.google.com/search?q=https://rydmike.com/flexcolorschemedemo/v7/%23/) で確認でき、好みの設定をコピーして持ち込むことも可能です。

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
  expect(container.read(themeModeProvider), ThemeMode.dark);
});
```

---
