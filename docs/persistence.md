# データ永続化・ローカルDB（SharedPreferences / Drift / SecureStorage）

本プロジェクトでは、データの性質や用途に合わせて3種類の永続化手法を使い分けています。

1. **SharedPreferencesAsync**: テーマ設定や軽量なAPIキャッシュなど、Key-Value形式の単純なデータの保存。
2. **Drift（SQLite）**: メモ一覧やオフライン対応が必要な複雑な構造を持つデータの保存。強力なクエリや型安全なテーブル定義が可能です。
3. **FlutterSecureStorage**: 認証トークンなど、よりセキュアに保存したい機密情報向け。

---

## 📁 関連ファイル構成

データ永続化のロジックは直接UIから呼び出すのではなく、用途ごとにラッパークラス（Repository層やStorage層）を作成し、責務をカプセル化しています。

```plaintext
lib/src/core/storage/
 ├── shared_preferences_provider.dart  # SharedPreferencesAsyncの提供
 ├── cache_manager.dart                # APIレスポンス等のキャッシュ管理
 ├── secure_storage_provider.dart      # FlutterSecureStorageの提供
 └── token_storage.dart                # 認証トークンの管理

lib/src/app/database/
 └── app_database.dart                 # Driftデータベース本体（テーブルの統合管理）

lib/src/core/database/
 └── database_provider.dart            # AppDatabaseのインスタンスを提供するRiverpod
```

---

## 💡 Drift（SQLite）による本格的なローカルDB

複雑なデータ構造や、オフライン環境でもデータを自由に操作（作成・更新・削除）したい場合は、**Drift** を採用しています。

### 1. 型安全なテーブル定義と生成

Dartのクラスとしてテーブルを定義でき、`build_runner` によって型安全なクエリコードが自動生成されます。

### 2. Streamによるリアルタイム同期

DBの値が変更されると、それを監視しているUIが自動的に更新される `watch` 機能を備えています。これにより、複雑な状態管理をDB層に委ねることができ、コードがシンプルになります。

### 3. オフラインファースト設計

リモート（API）から取得したデータを一度DBに保存し、UIは常にDBを参照する構成にすることで、電波のない場所でもアプリを快適に利用できる「オフラインファースト」な設計を実現しています。

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
      expect(database.schemaVersion, 1);
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
