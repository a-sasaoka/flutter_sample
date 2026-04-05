# APIキャッシュ対応（SharedPreferencesAsyncベース）

このプロジェクトでは、APIレスポンスを一定時間キャッシュして再利用することで、通信効率とユーザー体験を向上させています。
キャッシュは最新の `SharedPreferencesAsync` を用いて実現しており、外部の巨大なデータベースパッケージを追加せずに軽量かつ非同期に動作します。

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

以下の例では、`RefreshIndicator` を利用してスワイプ操作で最新データを取得します。

```dart
// lib/src/features/user/presentation/user_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: usersAsync.when(
        // skipLoadingOnRefresh がデフォルトで true のため、
        // スワイプ更新中も画面が真っ白にならず、以前のデータが表示され続けます。
        data: (list) => RefreshIndicator(
          // 💡 Notifierのカスタムメソッドを呼び出し、強制的にAPIから再取得！
          onRefresh: () => ref.read(userProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => ListTile(title: Text(list[i].name)),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorUnknown)),
      ),
    );
  }
}
```

## 💡 補足とアーキテクチャの解説

- `ref.read(userProvider.notifier).refresh()` を呼ぶと、内部で `UserRepository.fetchUsers(forceRefresh: true)` が実行されます。
- これにより、物理ストレージ（SharedPreferences）に有効なキャッシュが残っていても、それを無視して確実に最新のデータをサーバーへ取りに行きます。
- 取得完了後、新しいデータが `CacheManager` を通じて上書き保存されるため、常に最新のキャッシュが保たれます。
- **通常の画面遷移時**は引数なしの `fetchUsers()` が呼ばれるため、キャッシュが有効期限内であればAPI通信は行われず、瞬時に画面が表示される最高のUXを実現しています。

---
