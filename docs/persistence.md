# データ永続化・ローカルDB（SharedPreferences / Drift / SecureStorage）

本プロジェクトでは、データの性質や用途に合わせて3種類の永続化手法を使い分けています。

1. **SharedPreferencesAsync**: テーマ設定や軽量なAPIキャッシュなど、Key-Value形式の単純なデータの保存。
2. **Drift（SQLite）**: オフライン対応が必要な複雑な構造を持つデータの保存。強力なクエリや型安全なテーブル定義が可能です。
3. **FlutterSecureStorage**: 認証トークンなど、よりセキュアに保存したい機密情報向け。

---

## 📁 基盤層のファイル構成

永続化の仕組みは `lib/src/core/` および `lib/src/app/` に集約されています。具体的な機能（メモ帳など）での活用方法は、[メモ機能のドキュメント](./memos.md) を参照してください。

```plaintext
lib/src/core/storage/
 ├── shared_preferences_provider.dart  # SharedPreferencesAsyncの提供
 ├── cache_manager.dart                # APIレスポンス等のキャッシュ管理
 ├── secure_storage_provider.dart      # FlutterSecureStorageの提供
 └── token_storage.dart                # 認証トークンの管理

lib/src/app/database/
 └── app_database.dart                 # Driftデータベース本体（テーブルの統合管理）

lib/src/core/database/
 ├── database_provider.dart            # AppDatabaseの提供とリソース管理
 └── drift_talker_interceptor.dart     # Talkerへのクエリログ出力
```

---

## 💡 Drift（SQLite）による本格的なローカルDB

複雑なデータ構造や、オフライン環境でもデータを自由に操作（作成・更新・削除）したい場合は、**Drift** を採用しています。

### 1. 型安全なテーブル定義とDAOの活用

Dartのクラスとしてテーブルを定義でき、`build_runner` によって型安全なクエリコードが自動生成されます。\
本プロジェクトでは、クエリロジックが Repository 層に溢れないよう、機能ごとに **DAO (Data Access Object)** を作成してカプセル化しています。

また、`AppDatabase` クラス自体は「データベースの構造（テーブル定義）」にのみ責任を持ち、具体的な接続方法（スマホのファイルシステムやメモリ等）は一切知りません。この設計（疎結合）により、ユニットテストが非常に容易になっています。

### 2. リソース管理とライフサイクル

`database_provider.dart` では、データベース接続（Executor）の作成と DB インスタンスの生成を分離しています。

- **`databaseExecutorProvider`**: データベースの接続そのものを提供（`drift_flutter` を使用）。
- **`appDatabaseProvider`**: 上記の Executor を受け取って `AppDatabase` を初期化します。Riverpod の `ref.onDispose` を利用して、プロバイダーが破棄された際にデータベース接続を確実に閉じる（`db.close()`）よう実装されています。

この構成により、`AppDatabase` のインスタンス化には必ず有効な Executor が必要となり、ロギング（Interceptor）の適用漏れなどを防ぐことができます。

### 3. 統合ロギング（Talker）との連携

`DriftTalkerInterceptor` を通じて、実行されたすべての SQL クエリが `Talker` ログに出力されます。

- **パフォーマンス監視**: 各クエリの実行時間（ミリ秒）が記録され、スロークエリの特定に役立ちます。
- **エラー詳細**: 例外発生時、失敗した SQL 文と引数が詳細にログ出力され、デバッグ効率が向上しています。

### 4. Streamによるリアルタイム同期

DBの値が変更されると、それを監視しているUIが自動的に更新される `watch` 機能を備えています。これにより、複雑な状態管理をDB層に委ねることができ、コードがシンプルになります。

### 5. オフラインファースト設計の実装例

具体的な実装パターン（同期ロジック等）については、[メモ機能の実装詳細](./memos.md) を参照してください。

---

## 💡 SharedPreferencesAsync 採用のメリットと設計

これまでの Flutter 開発では、`SharedPreferences.getInstance()` の読み込みを待つために `main.dart` の処理をブロックしたり、Riverpod で `UnimplementedError` を投げてオーバーライドするといった複雑な初期化処理が「定石」とされてきました。

本プロジェクトでは `SharedPreferencesAsync` を用いることで、これらの複雑なハックを完全に排除しています。

### 1. シンプルで安全なプロバイダ定義

```dart
// lib/src/core/storage/shared_preferences_provider.dart
@Riverpod(keepAlive: true)
SharedPreferencesAsync sharedPreferences(Ref ref) {
  // SharedPreferencesAsync はコンストラクタで I/O を行わないため、同期的に提供可能
  return SharedPreferencesAsync();
}
```

### 2. コンストラクタ注入（DI）の徹底

`CacheManager` や `TokenStorage` は、コンストラクタで直接 `SharedPreferencesAsync` を受け取ります。これにより、Riverpod の `Ref` に依存せず、純粋な Dart クラスとして動作します。

```dart
// 使用例
final manager = CacheManager(
  prefs: SharedPreferencesAsync(),
  getCurrentDateTime: () => DateTime.now(),
);
```

### 3. 非同期前提のアーキテクチャ

データの読み書き自体（`getString`, `setString` 等）は非同期のため、UI層からは Riverpod の `AsyncValue`（`ref.watch(xxxProvider).when(...)`）などを活用し、「データ取得中はローディングを出す」といった、Flutter本来の宣言的なUI構築に自然にフィットする作りになっています。

---

## 📦 各ラッパークラスの役割

生の `SharedPreferencesAsync` に直接アクセスさせず、目的に特化したクラスを経由させることで、キー名のタイポを防ぎ、ロジックを安全に保っています。

### CacheManager (`cache_manager.dart`)

APIのレスポンスなどを一時的に保存するクラスです。
単なる保存だけでなく、**保存日時を付与し、有効期限（TTL）を過ぎたデータは非同期で破棄する**という実用的なキャッシュロジックが組み込まれています。

### TokenStorage (`token_storage.dart`)

アクセストークンやリフレッシュトークンなど、認証に関わる情報を `FlutterSecureStorage` を用いてセキュアに永続化します。DioのInterceptor（通信割り込み）と連携し、APIリクエスト時に自動でトークンをヘッダーに付与するために使用されます。

---

## 🧪 テスト時の永続化のモック

永続化層はすべて Riverpod で抽象化されているため、テスト時にインメモリデータベースやモックへ差し替えることが容易です。

- **Drift**: `NativeDatabase.memory()` を使うことで、高速なインメモリテストが可能です。

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      // テスト時はメモリ上で動くデータベースを使用する
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('schemaVersion returns 1', () {
      check(database.schemaVersion).equals(1);
    });

    // ... その他のテストケース
  });
}
```

- **SharedPreferences**: `SharedPreferencesAsync.setMockInitialValues()` で初期値を設定できます。

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

    // ... アサーション
  });
}
```

この構成により、実際のデバイスストレージに依存しない、高速でクリーンなテスト環境を実現しています。

---
