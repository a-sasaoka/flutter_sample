# Firebase Analytics（自動画面トラッキング & 型安全なイベント基盤）

本プロジェクトでは、GoRouter と Firebase Analytics を組み合わせた **自動 screen_view 送信** と、EnumとRiverpodを活用した **型安全な統合イベント管理** を行っています。

---

## 📁 関連ファイル構成

```plaintext
lib/src/core/analytics/
 ├── analytics_event.dart                # 💡 送信するイベントを定義したEnum（型安全）
 ├── analytics_service.dart              # イベント送信・ユーザー属性設定の実行
 └── typed_route_analytics_observer.dart # 画面遷移の自動追跡（カスタムObserver）
```

---

## 🔍 自動画面トラッキング（GoRouter × TypedRouteAnalyticsObserver）

アプリ内の画面移動を Firebase Analytics に **自動で送信** します。\
GoRouter の `NavigatorObserver` を拡張した `TypedRouteAnalyticsObserver` を使用しています。

### 特徴

- `go_router_builder` で生成されるクラス名（例: `$HomeRoute`）から自動で `$` を除去し、綺麗な `screen_class` として送信します。
- 画面遷移のたびに Talker にも出力されるため、開発者用ログ（TalkerScreen）や DebugView と合わせてリアルタイムな動作確認が容易です。

---

## 🧩 AnalyticsService と Enum による型安全なイベント管理

UI層から FirebaseAnalytics を直接操作するのではなく、**`AnalyticsEvent` (Enum) と `AnalyticsService`** を導入し、ミス（タイポ）のない安全な送信を実現しています。

### 主な役割と設計のポイント

- **型安全 (Type-safe)**: イベント名を Enum で指定するため、実装漏れやタイポを防ぎます。
- **メタデータの自動付与**: イベント送信時に、`timestamp` が自動的にパラメータに付与されます。
- **ユーザー識別と属性**: ユーザー ID (`setUserId`) や、会員ランク等のユーザープロパティ (`setUserProperty`) の設定もサポートしています。
- **クラッシュ防止**: 送信処理は `try-catch` で保護されており、通信エラー等が発生してもアプリの動作を止めない安全な設計です。

### 使用方法

- **イベントの送信（UI層から）**: `ref.read(analyticsServiceProvider).logEvent(event: AnalyticsEvent.xxx, parameters: ...)` を呼び出すことで、型安全にイベントが送信されます。具体的な呼び出し例は [home_screen.dart](../lib/src/features/home/presentation/home_screen.dart) などを参照してください。
- **ユーザー識別と属性設定**: `setUserId()` や `setUserProperty()` を使用してログインユーザーの追跡やセグメント分析を行います。実装詳細は [analytics_service.dart](../lib/src/core/analytics/analytics_service.dart) および [analytics_service_test.dart](../test/src/core/analytics/analytics_service_test.dart) を参照してください。

---

## ⭐ この構成のメリットまとめ

| 項目             | 内容                                                             |
| ---------------- | ---------------------------------------------------------------- |
| **型安全性**     | Enum管理により、イベント名のタイポをコンパイルレベルで排除       |
| **ユーザー分析** | 属性やIDの紐付けにより「誰が何をしたか」の深い分析が可能         |
| **テスト容易性** | コンストラクタでの注入（DI）により、単体テストが非常に容易       |
| **保守性**       | AnalyticsService にロジックを集約し、UI層をシンプルに保つ        |
| **安定性**       | `try-catch` による保護で、分析基盤のエラーがアプリに影響しない   |
| **可読性**       | `$` 除去などのフォーマット処理により、コンソール上のデータが綺麗 |

実務レベルの Analytics 基盤として、大規模なアプリ開発でも破綻しない、極めて堅牢で拡張しやすい形になっています。

---
