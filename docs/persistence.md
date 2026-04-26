# データ永続化・キャッシュ（SharedPreferencesAsync）

本プロジェクトでは、テーマ設定、APIのレスポンスキャッシュ、認証トークンなどのデータを永続化するために、最新の `SharedPreferencesAsync` を採用しています。

従来の `SharedPreferences` が抱えていた「アプリ起動時の同期的な読み込みブロック」を解消し、よりセキュアでパフォーマンスの高い非同期アーキテクチャを構築しています。

---

## 📁 関連ファイル構成

データ永続化のロジックは直接UIから呼び出すのではなく、用途ごとにラッパークラス（Repository層やStorage層）を作成し、責務をカプセル化しています。

```plaintext
lib/src/core/storage/
 ├── shared_preferences_provider.dart  # SharedPreferencesAsyncのインスタンスを提供する大元
 ├── cache_manager.dart                # APIレスポンス等のキャッシュ管理（有効期限付き）
 └── token_storage.dart                # 認証トークン（Bearer）の保存・取得・削除
```

---

## 💡 SharedPreferencesAsync 採用のメリットと設計

これまでの Flutter 開発では、`SharedPreferences.getInstance()` の読み込みを待つために `main.dart` の処理をブロックしたり、Riverpod で `UnimplementedError` を投げてオーバーライドするといった複雑な初期化処理が「定石」とされてきました。

本プロジェクトでは `SharedPreferencesAsync` を用いることで、これらの複雑なハックを完全に排除しています。

### 1. シンプルで安全なプロバイダ定義

```dart
// lib/src/core/storage/shared_preferences_provider.dart
@Riverpod(keepAlive: true)
Future<SharedPreferencesAsync> sharedPreferences(Ref ref) async {
  // 非同期で即座にインスタンスを返却。起動ブロックや main.dart でのオーバーライドは不要！
  return SharedPreferencesAsync();
}
```

### 2. 非同期（Async）前提のアーキテクチャ

データの読み書きが完全に非同期化されたため、UI層からは Riverpod の `AsyncValue`（`ref.watch(xxxProvider).when(...)`）などを活用し、「データ取得中はローディングを出す」といった、Flutter本来の宣言的なUI構築に自然にフィットする作りになっています。

---

## 📦 各ラッパークラスの役割

生の `SharedPreferencesAsync` に直接アクセスさせず、目的に特化したクラスを経由させることで、キー名のタイポを防ぎ、ロジックを安全に保っています。

### CacheManager (`cache_manager.dart`)

APIのレスポンスなどを一時的に保存するクラスです。
単なる保存だけでなく、**保存日時を付与し、有効期限（TTL）を過ぎたデータは非同期で破棄する**という実用的なキャッシュロジックが組み込まれています。

### TokenStorage (`token_storage.dart`)

アクセストークンやリフレッシュトークンなど、認証に関わる情報を永続化します。DioのInterceptor（通信割り込み）と連携し、APIリクエスト時に自動でトークンをヘッダーに付与するために使用されます。

---

## 🧪 テスト時の永続化のモック

永続化層がRiverpodで切り出されているため、ユニットテストやWidgetテストでのモックへの差し替えも非常に簡単に行えます。

```dart
void main() {
  testWidgets('SharedPreferencesAsyncを利用したテスト例', (tester) async {
    // 💡 SharedPreferencesAsync 用のインメモリキャッシュ等をテスト用に設定
    SharedPreferencesAsync.setMockInitialValues({
      'theme_mode': 'dark',
    });

    // プロバイダの差し替えが不要な場合もありますが、
    // 必要に応じて Repository や Storage クラス自体を mocktail でモック化して注入します。
    await tester.pumpWidget(
      ProviderScope(
        child: const MyApp(),
      ),
    );
  ProviderScope(
        child: const MyApp(),
      ),
    );
    
    // ... アサーション
  });
}
```

この構成により、実際のデバイスストレージに依存しない、高速でクリーンなテスト環境を実現しています。

---
