# トークン認証対応（Bearer Token + 自動リフレッシュ）

このプロジェクトでは、API通信にBearerトークン認証を追加し、トークンの自動付与および自動リフレッシュ処理を実装しています。
これにより、ログイン後のすべての通信で認証ヘッダーを自動的に付与し、有効期限切れ時に再取得を行います。

---

## 📁 ファイル構成

```plaintext
lib/src/core/auth/
 ├── token_storage.dart       # トークンの永続化（SharedPreferences）
 ├── auth_repository.dart     # ログイン・リフレッシュ処理
 └── token_interceptor.dart   # DioのInterceptorで自動付与・更新
```

---

## 🧩 Dioへの組み込み順序（重要）

Interceptorの登録順序は以下の通りにしてください👇

```dart
dio.interceptors.add(ref.read(tokenInterceptorProvider)); // ① トークン付与・リフレッシュ
dio.interceptors.add(ref.read(dioInterceptorProvider));   // ② ログ出力・エラーハンドリング
```

### 💡 理由

| 順番 | 説明 |
|------|------|
| ① tokenInterceptor | リクエスト前に認証ヘッダーを追加・401検知でリフレッシュ |
| ② dioInterceptor | 通信全体のログ・例外処理を担当（最終層で処理） |

> 順番を逆にすると、ログにトークンが含まれなかったり、401エラー時の自動リフレッシュが動作しないことがあります。

---

## ✅ 動作確認手順

1. `/auth/login` に有効なユーザー情報をPOSTしてログイン  
2. `SharedPreferences` にトークンが保存されていることを確認  
3. 他のAPI通信で `Authorization` ヘッダーが自動付与されることを確認  
4. トークン失効時に `/auth/refresh` が自動呼び出されることを確認  

---

この構成により、アプリ全体で安全かつ自動化された認証フローを実現できます。

---

## 💡 補足

- `authRepositoryProvider` を通じてログインAPIを呼び出し、トークンを保存します。  
- 以降のAPI通信では `tokenInterceptorProvider` により自動で認証ヘッダーが付与されます。  
- トークンの有効期限が切れると自動的にリフレッシュ処理が走ります。

---
