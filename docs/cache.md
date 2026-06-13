# APIキャッシュ対応（SharedPreferencesAsyncベース）

このプロジェクトでは、データの性質に合わせて2種類のキャッシュ/保存戦略をとっています。

1. **軽量APIキャッシュ（SharedPreferencesAsync）**: ユーザー情報など、単純なAPIレスポンスを一定時間保持します。実装が容易で軽量です。
2. **本格的なオフラインデータ（Drift）**: メモ一覧など、オフラインでの編集・同期が必要な複雑なデータはローカルDB（Drift）で管理します。詳細は [データ永続化のドキュメント](./persistence.md) を参照してください。

---

## 📁 関連ファイル構成

```plaintext
lib/src/core/storage/
 └── cache_manager.dart              # キャッシュの保存・取得・TTL(有効期限)管理とプロバイダ定義

lib/src/features/user/
 ├── data/user_repository.dart       # forceRefreshフラグでキャッシュの有無を判定しAPI通信を制御
 └── application/user_notifier.dart  # 強制更新（refresh）メソッドを提供
```

---

## ✅ メリット

| 項目           | 内容                                                   |
| -------------- | ------------------------------------------------------ |
| 高速化         | 2回目以降はAPI通信なしで即表示                         |
| オフライン対応 | ネットワーク切断時でも前回データを利用可能             |
| パフォーマンス | `Async` ストレージによりメインスレッドをブロックしない |
| シンプル       | パッケージ追加不要・メンテナンス性が高い               |

---

## 🔄 Pull to Refreshによる強制キャッシュ更新（実践的アプローチ）

Riverpodの標準機能である `ref.refresh` は「メモリ上の状態」を破棄しますが、物理デバイス（`SharedPreferences`）に保存されたキャッシュまでは消去してくれません。

そのため、このプロジェクトではユーザーが「引っ張って更新」をした際に、**確実にキャッシュを無視してAPIから最新データを取得するための `forceRefresh` フラグ** を Repository に実装し、Notifier 経由で呼び出しています。

また、**「リフレッシュが失敗（オフライン等）した際に、キャッシュがあればそれを表示し続ける」**という高度な UX を実現するため、UI側で `AsyncValue` のパターンマッチングを工夫しています。

以下の例では、`RefreshIndicator` を利用してスワイプ操作で最新データを取得します。

```dart
// lib/src/features/user/presentation/user_list_screen.dart

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: switch (usersAsync) {
        // 💡 データがある場合 (エラーやローディング中でも、データがあれば表示)
        AsyncValue(value: (final value, _)?) when value.isNotEmpty => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) => _UserCard(user: value[index]),
          ),
        ),
        // 💡 エラー状態 (データがない場合のみ)
        AsyncError() => ErrorWidget(...),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
```

## 💡 補足とアーキテクチャの解説

- `ref.read(userProvider.notifier).refresh()` を呼ぶと、内部で `UserRepository.fetchUsers(forceRefresh: true)` が実行されます。
- これにより、物理ストレージ（SharedPreferences）に有効なキャッシュが残っていても、それを無視して確実に最新のデータをサーバーへ取りに行きます。
- **データ取得日時の管理**: `CacheManager` を通じてデータの保存日時（タイムスタンプ）も取得可能にしており、情報の鮮度を UI に表示する際に利用しています。
- **通常の画面遷移時**は引数なしの `fetchUsers()` が呼ばれるため、キャッシュが有効期限内であればAPI通信は行われず、瞬時に画面が表示される最高のUXを実現しています。

---
