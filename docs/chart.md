# グラフ表示機能 (fl_chart)

このセクションでは、`fl_chart` ライブラリを使用して、ユーザーが入力したデータを元に動的なグラフを表示する機能、および期間切り替えに対応した売上推移グラフについて解説します。

---

## 機能概要

この機能では、以下の操作が可能です。

1. **データ入力**: 複数の値（ラベルと数値）をユーザーが入力します。
2. **グラフ選択**: 折れ線グラフ、棒グラフ、円グラフの3種類から表示形式を選択できます。
3. **動的な描画**: 入力されたデータに基づいて、リアルタイムにグラフが描画されます。
4. **売上推移グラフ**: 期間（7日間 / 14日間）を切り替え可能な折れ線グラフを表示し、スムーズなアニメーション、グラデーション、見切れ防止マージン、カスタムTooltip、売上サマリー（合計・日別平均）を提供します。

---

## 技術スタック

- **ライブラリ**: [fl_chart](https://pub.dev/packages/fl_chart)
- **状態管理**: Riverpod (`@riverpod` Notifier)
- **データモデル**: Freezed (Sealed classes)

---

## ディレクトリ構成

```plaintext
lib/src/features/chart
├── application
│   ├── chart_notifier.dart              # 汎用グラフデータの状態管理
│   └── chart_state.dart                 # 汎用グラフの状態定義
├── domain
│   ├── chart_item.dart                  # 個別のデータ項目（ラベルと値）
│   └── chart_type.dart                  # グラフの種類（Enum）
└── presentation
    ├── controllers
    │   ├── sales_chart_controller.dart  # 売上推移グラフの状態管理
    │   └── sales_chart_state.dart       # 売上推移グラフの状態定義
    ├── widgets
    │   └── animated_sales_chart.dart    # アニメーション付き売上推移グラフ
    ├── chart_display_screen.dart        # 汎用グラフ表示画面
    ├── chart_input_screen.dart          # データ入力画面
    └── sales_chart_screen.dart          # 売上推移グラフ専用画面
```

---

## 実装のポイント

### 1. 汎用グラフの状態管理 (`ChartNotifier`)

グラフに表示するデータのリストや、選択されているグラフの種類を `ChartNotifier` で一括管理しています。
データの追加・削除、グラフ種類の変更などはこの Notifier を通じて行われます。

- **DIの活用**: 項目の ID 生成に `uuidProvider` を使用しています。これにより、テスト時に ID を固定し、予測可能な検証が可能です。
- **リセット機能**: 全てのデータを一括削除する `reset()` メソッドを提供しています。
- **永続性 (keepAlive)**: `keepAlive: true` を設定しているため、入力画面と表示画面を往復してもデータが保持されます。

### 2. 売上推移グラフの状態管理 (`SalesChartController`)

期間フィルター（7日間 / 14日間）の切り替えや、座標データ・日付ラベル・最大Y軸・売上サマリー（合計・日別平均）の算出を管理しています。

- **Sealed classes + Freezed**: 状態モデルは Freezed で定義され、期間変更に応じた新しい状態インスタンスの生成を行います。
- **Dart 3 Records**: サンプルデータには Dart 3 の Records を活用して型安全に保持しています。

### 3. 多様なグラフ形式への対応

`ChartType` という Enum を定義し、各グラフ形式に応じた `fl_chart` のウィジェット（`LineChart`, `BarChart`, `PieChart`）を切り替えて表示しています。

### 4. UI/UX の工夫

- **入力画面**: 各項目をカード形式で表示し、項目の区切りを明確にしています。AppBarのボタンから汎用グラフ表示画面および売上推移グラフ画面へ遷移可能です。
- **売上推移画面**: 上部に `SegmentedButton` による期間切り替えを配置し、合計売上・日別平均のサマリーカードと、下部グラデーション・見切れ防止マージン・カスタムTooltipを備えた折れ線グラフを表示します。
- **多言語対応 (L10n)**: グラフのタイトルや期間ラベル、売上サマリー文言などは、`app_localizations.dart` を使用して日本語と英語に対応しています。

---

## テスト

この機能には、以下のテストが含まれています。

- **Unit Test**:
  - `ChartNotifier`: データの追加・削除・クリア（リセット）が正しく状態に反映されるか。`uuidProvider` のモックによる検証。
  - `ChartType`: 各 Enum 値が正しいローカライズラベルを返すか。
  - `SalesChartController`: 初期状態（7日間）および14日間への切り替え時の座標・ラベル・サマリー算出の検証。
- **Widget Test**:
  - `ChartInputScreen`: フォーム入力、データの追加、個別の削除、一括削除ボタンの動作、各画面遷移の確認。
  - `ChartDisplayScreen`: 選択したグラフ形式に応じて正しいチャートウィジェットが表示されるか。データのスクロール表示。
  - `AnimatedSalesChart`: 7日間・14日間の描画、各軸ラベルのフォーマット・間引き、Tooltip・グリッド・ドットの各種コールバックの動作確認。
  - `SalesChartScreen`: タイトル・サマリーカード・グラフの初期表示、期間切り替え時の数値更新の確認。
- **Golden Test**:
  - `ChartDisplayScreen`: 折れ線・棒・円グラフ・空データの全4パターンでの表示確認。
  - `ChartInputScreen`: 入力画面全体のレイアウト確認。
  - `SalesChartScreen`: 7日間（Light Mode）および14日間（Dark Mode）での画面全体の表示確認。

---

## 関連ファイル

- `lib/src/features/chart/presentation/chart_display_screen.dart`
- `lib/src/features/chart/presentation/chart_input_screen.dart`
- `lib/src/features/chart/presentation/sales_chart_screen.dart`
- `lib/src/features/chart/presentation/widgets/animated_sales_chart.dart`
- `lib/src/features/chart/presentation/controllers/sales_chart_controller.dart`
- `lib/src/features/chart/presentation/controllers/sales_chart_state.dart`
- `lib/src/features/chart/application/chart_notifier.dart`
- `test/src/features/chart/` (テストコード一式)
