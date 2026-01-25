# Firebase Analytics（自動画面トラッキング & 共通イベント基盤）

本プロジェクトでは、GoRouter と Firebase Analytics を組み合わせた  
**自動 screen_view 送信 + 統合イベント管理** を行っています。

## 🔍 自動画面トラッキング（GoRouter × TypedRouteAnalyticsObserver）

アプリ内の画面移動を Firebase Analytics に **自動で送信**します。  
GoRouter の `NavigatorObserver` を利用し、送信する内容をカスタマイズできるようにしています。

### 特徴

- 自動で付与するパラメータを簡単に追加可能
- DebugView でリアルタイム確認可能

### 📁 関連ファイル

```plaintext
lib/src/core/router/app_router.dart
```

### コード概要

```dart
GoRouter(
  observers: [
    TypedRouteAnalyticsObserver(ref),
  ],
);
```

### 実際に送信されるデータ例

```plaintext
screen_view {
  screen_class: "settings",
  screen_name: "settings"
}
```

## 🧩 AnalyticsService（イベント送信の統合管理）

UI 層から FirebaseAnalytics を直接触らないようにするため、  
**AnalyticsService** を導入し、カスタムイベント送信を統一しています。

### 📁 ファイル構成

```plaintext
lib/src/core/analytics/analytics_service.dart
```

### 主な役割

- 任意イベント（例: ボタンタップ、完了アクションなど）の送信  
- GoRouter の自動画面トラッキングと組み合わせて、アプリ全体を Analytics で可視化

### 使用例

```dart
ref.read(analyticsServiceProvider).logEvent(
  name: 'home_analytics_button_tapped',
);
```

## ⭐ この構成のメリットまとめ

| 項目 | 内容 |
|------|------|
| 保守性 | イベント送信を AnalyticsService に集約 |
| 拡張性 | 他の Firebase 機能（Performance / A/B Testing）とも連携しやすい |

実務レベルの Analytics 基盤として、イベント設計や分析設計にも拡張しやすい形になっています。
