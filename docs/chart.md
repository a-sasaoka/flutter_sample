# グラフ表示機能 (fl_chart)

このセクションでは、`fl_chart` ライブラリを使用して、ユーザーが入力したデータを元に動的なグラフを表示する機能について解説します。

---

## 機能概要

この機能では、以下の操作が可能です。

1. **データ入力**: 複数の値（ラベルと数値）をユーザーが入力します。
2. **グラフ選択**: 折れ線グラフ、棒グラフ、円グラフの3種類から表示形式を選択できます。
3. **動的な描画**: 入力されたデータに基づいて、リアルタイムにグラフが描画されます。

---

## 技術スタック

- **ライブラリ**: [fl_chart](https://pub.dev/packages/fl_chart)
- **状態管理**: Riverpod (`@riverpod` Notifier)
- **データモデル**: Freezed

---

## ディレクトリ構成

```plaintext
lib/src/features/chart
├── application
│   ├── chart_notifier.dart      # グラフデータの状態管理
│   └── chart_state.dart         # グラフの状態定義
├── domain
│   ├── chart_item.dart          # 個別のデータ項目（ラベルと値）
│   └── chart_type.dart          # グラフの種類（Enum）
└── presentation
    ├── chart_display_screen.dart # グラフ表示画面
    └── chart_input_screen.dart   # データ入力画面
```

---

## 実装のポイント

### 1. 状態管理 (`ChartNotifier`)

グラフに表示するデータのリストや、選択されているグラフの種類を `ChartNotifier` で一括管理しています。
データの追加・削除、グラフ種類の変更などはこの Notifier を通じて行われます。

### 2. 多様なグラフ形式への対応

`ChartType` という Enum を定義し、各グラフ形式に応じた `fl_chart` のウィジェット（`LineChart`, `BarChart`, `PieChart`）を切り替えて表示しています。

### 3. 多言語対応 (L10n)

グラフのタイトルや各チャートのラベル名は、`app_localizations.dart` を使用して日本語と英語に対応しています。

---

## テスト

この機能には、以下のテストが含まれています。

- **Unit Test**:
  - `ChartNotifier`: データの追加・削除・クリアが正しく状態に反映されるか。
  - `ChartType`: 各 Enum 値が正しいローカライズラベルを返すか。
- **Widget Test**:
  - `ChartInputScreen`: フォーム入力、データの追加、削除ボタンの動作、画面遷移の確認。
  - `ChartDisplayScreen`: 選択したグラフ形式に応じて正しいチャートウィジェットが表示されるか。

---

## 関連ファイル

- `lib/src/features/chart/presentation/chart_display_screen.dart`
- `lib/src/features/chart/presentation/chart_input_screen.dart`
- `lib/src/features/chart/application/chart_notifier.dart`
- `test/src/features/chart/` (テストコード一式)
