# Firebase Analytics（自動画面トラッキング & 型安全なイベント基盤）

本プロジェクトでは、GoRouter と Firebase Analytics を組み合わせた **自動 screen_view 送信** と、EnumとRiverpodを活用した **型安全な統合イベント管理** を行っています。

---

## 📁 関連ファイル構成

```plaintext
lib/src/core/analytics/
 ├── analytics_event.dart      # 💡 送信するイベントを定義したEnum（型安全）
 └── analytics_service.dart    # イベント送信の実行とエラーハンドリング

lib/src/app/router/
 └── app_router.dart           # GoRouter設定とカスタムObserverの登録
```

---

## 🔍 自動画面トラッキング（GoRouter × TypedRouteAnalyticsObserver）

アプリ内の画面移動を Firebase Analytics に **自動で送信** します。
GoRouter の `NavigatorObserver` を拡張し、送信する内容をカスタマイズしています。

### 特徴

- `go_router_builder` で生成されるクラス名（例: `$HomeRoute`）から自動で `$` を除去し、綺麗な `screen_class` として送信します。
- 画面遷移のたびに Talker にも出力されるため、開発者用ログ（TalkerScreen）や DebugView と合わせてリアルタイムな動作確認が容易です。

### コード概要（app_router.dart）

```dart
GoRouter(
  // ...
  observers: [
    TypedRouteAnalyticsObserver(
      analytics: ref.watch(firebaseAnalyticsProvider),
      talker: ref.watch(loggerProvider),
    ),
  ],
);
```

---

## 🧩 AnalyticsService と Enum による型安全なイベント管理

UI層から FirebaseAnalytics を直接操作するのではなく、**`AnalyticsEvent` (Enum) と `AnalyticsService`** を導入し、タイポ（打ち間違い）のない安全なイベント送信を実現しています。

### 主な役割と設計のポイント

- **型安全 (Type-safe)**: イベント名を文字列ではなく Enum (`AnalyticsEvent.homeButtonTapped` など) で指定するため、実装漏れやミスを防ぎます。
- **メタデータの自動付与**: イベント送信時に、`currentDateTimeProvider` を利用して `timestamp` が自動的にパラメータに付与されます。
- **クラッシュ防止**: 送信処理は `try-catch` で保護されており、通信エラー等が発生してもアプリ本体の動作を止めず、Talker に警告を出すだけの安全な設計です。

### 使用例（UI層からの呼び出し）

```dart
// 💡 Enum を指定するだけで、安全かつ簡単にイベントとタイムスタンプが送信される
ref.read(analyticsServiceProvider).logEvent(
  event: AnalyticsEvent.homeButtonTapped,
  parameters: {
    'custom_param': 'value', // 必要に応じて追加パラメータも渡せます
  },
);
```

---

## ⭐ この構成のメリットまとめ

| 項目         | 内容                                                             |
| ------------ | ---------------------------------------------------------------- |
| **型安全性** | Enum管理により、イベント名のタイポをコンパイルレベルで排除       |
| **保守性**   | AnalyticsService にロジックを集約し、UI層をシンプルに保つ        |
| **安定性**   | `try-catch` による保護で、分析基盤のエラーがアプリに影響しない   |
| **可読性**   | `$` 除去などのフォーマット処理により、コンソール上のデータが綺麗 |

実務レベルの Analytics 基盤として、大規模なアプリ開発でも破綻しない、極めて堅牢で拡張しやすい形になっています。

---
