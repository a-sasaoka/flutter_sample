## APIキャッシュ対応（SharedPreferencesベース）

このプロジェクトでは、APIレスポンスを一定時間キャッシュして再利用することで、通信効率とユーザー体験を向上させています。
キャッシュは `SharedPreferences` を用いて実現しており、外部パッケージを追加せずに軽量に動作します。

---

### 📁 追加ファイル構成

```plaintext
lib/src/core/storage/
 ├── cache_manager.dart        # キャッシュ共通クラス
 └── cache_provider.dart       # Riverpodプロバイダ

lib/src/features/user/data/
 └── user_repository.dart      # fetchUsersをキャッシュ対応化
```

---

### ✅ メリット

| 項目 | 内容 |
|------|------|
| 高速化 | 2回目以降はAPI通信なしで即表示 |
| オフライン対応 | ネットワーク切断時でも前回データを利用可能 |
| シンプル | パッケージ追加不要・メンテナンス性が高い |

---

### 🔄 Pull to Refreshによるキャッシュ更新例

以下の例では、`RefreshIndicator` を利用してユーザーがスワイプ操作で最新データを取得します。

```dart
// lib/src/features/user/presentation/user_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    Future<void> onRefresh() async {
      // API再取得（キャッシュ無視）
      await ref
          .read(userNotifierProvider.notifier)
          .fetchUsers(forceRefresh: true);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: users.when(
        data: (list) => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) =>
                ListTile(title: Text(list[i].name)),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorUnknown)),
      ),
    );
  }
}
```

### 💡 補足

- `fetchUsers(forceRefresh: true)` によってキャッシュをスキップしてAPIを再取得します。  
- キャッシュ層 (`CacheManager`) に `clear()` を追加してから再保存することで、常に最新データを反映。  
- オフライン環境では前回キャッシュを自動で使用し、ユーザー体験を損なわずに動作します。

---
